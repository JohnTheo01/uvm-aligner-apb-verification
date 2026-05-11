`ifndef CFS_ALGN_MODEL_SV

    `define CFS_ALGN_MODEL_SV

    `uvm_analysis_imp_decl(_in_rx)
    `uvm_analysis_imp_decl(_in_tx)

    class cfs_algn_model 
        extends uvm_component
        implements uvm_ext_reset_handler;

        // Register Model
        cfs_algn_reg_block reg_block;

        // Env_config handler
        cfs_algn_env_config env_config;

        // Input ports handlers
        uvm_analysis_imp_in_rx#(cfs_md_item_mon, cfs_algn_model) port_in_rx;
        uvm_analysis_imp_in_tx#(cfs_md_item_mon, cfs_algn_model) port_in_tx;

        // Output ports to scoreboard
        uvm_analysis_port#(cfs_md_response) port_out_rx;
        uvm_analysis_port#(cfs_md_item_mon) port_out_tx;

        // Intertupt request port
        uvm_analysis_port#(bit) port_out_irq;

        // Rx FIFO handler
        protected uvm_tlm_fifo#(cfs_md_item_mon) rx_fifo;
        local process process_push_to_rx_fifo;

        // Buffer handler
        protected cfs_md_item_mon buffer[$];
        local process process_build_buffer;

        // TX FIFO handler
        protected uvm_tlm_fifo#(cfs_md_item_mon) tx_fifo;

        // Align process pointer
        local process process_align;

        // Event for tx acknowledgement
        protected uvm_event tx_complete;

        local process process_tx_ctrl;

        // ----------------------------------- FIFO Synchronization processes -----------------------------------
        process process_set_rx_fifo_empty;
        process process_set_rx_fifo_full;

        process process_set_tx_fifo_empty;
        process process_set_tx_fifo_full;

        `uvm_component_utils(cfs_algn_model)

        function new(string name = "", uvm_component parent);
            super.new(name, parent);

            port_in_rx = new("port_in_rx", this);
            port_in_tx = new("port_in_tx", this);

            port_out_rx = new("port_out_rx", this);
            port_out_tx = new("port_out_tx", this);

            port_out_irq = new("port_out_irq", this);

            rx_fifo = new("rx_fifo", this, 8);
            tx_fifo = new("tx_fifo", this, 8);

            tx_complete = new("tx_complete");
        endfunction

        virtual function void build_phase(uvm_phase phase);
            super.build_phase(phase);

            if (reg_block == null) begin
                reg_block = cfs_algn_reg_block::type_id::create("reg_block", this);

                reg_block.build();
                reg_block.lock_model();
            end
        endfunction

        virtual function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);

            begin 
                cfs_algn_clr_cnt_drop cbs = cfs_algn_clr_cnt_drop::type_id::create("cbs", this);

                cbs.cnt_drop = reg_block.STATUS.CNT_DROP;

                uvm_callbacks#(uvm_reg_field, cfs_algn_clr_cnt_drop)::add(
                    reg_block.CTRL.CLR, 
                    cbs
                );
            end
        endfunction

        virtual function void end_of_elaboration_phase(uvm_phase phase);
            super.end_of_elaboration_phase(phase);

            reg_block.CTRL.set_algn_data_width(env_config.get_algn_data_width());
        endfunction

        // ----------------------------------- Reset Logic -----------------------------------
        virtual function void handle_reset(uvm_phase phase);
            reg_block.reset("HARD");

            this.kill_process(process_push_to_rx_fifo);
            this.kill_process(process_build_buffer);
            this.kill_process(process_align);
            this.kill_process(process_tx_ctrl);

            this.kill_process(process_set_rx_fifo_empty);
            this.kill_process(process_set_rx_fifo_full);

            this.kill_process(process_set_tx_fifo_empty);
            this.kill_process(process_set_tx_fifo_full);

            rx_fifo.flush();
            tx_fifo.flush();
            buffer = {};

            tx_complete.reset();

            build_buffer_nb();
            align_nb();
            tx_ctrl_nb();
        endfunction

        virtual function void write_in_rx(cfs_md_item_mon item_mon);
            cfs_md_response response;

            if (item_mon.is_active() == 0) begin
                return;
            end

            response = this.get_exp_response(item_mon);

            case (response) 

                CFS_MD_OKAY: begin
                    push_to_rx_fifo_nb(item_mon);                
                end

                CFS_MD_ERR: begin
                    this.inc_count_drop(response);
                    port_out_rx.write(response);
                end

                default: begin
                    `uvm_fatal("ALGORITHM_ISSUE", 
                        $sformatf("Unsupported value for response: %0s", response.name())
                    )
                end

            endcase
        endfunction

        virtual function void write_in_tx(cfs_md_item_mon item_mon);
            if(item_mon.is_active() == 0) begin
                tx_complete.trigger();
            end
        endfunction

        protected virtual function cfs_md_response get_exp_response(cfs_md_item_mon item_mon);

            int unsigned data_width = env_config.get_algn_data_width();
            
            int size    = item_mon.data.size();
            int offset  = item_mon.offset;

            if (size == 0) begin
                return CFS_MD_ERR;
            end

            if ( ((data_width / 8) + offset) % size != 0 ) begin
                return CFS_MD_ERR;
            end 

            if ( offset + size > (data_width / 8) ) begin
                return CFS_MD_ERR;
            end
                
            return CFS_MD_OKAY;
        endfunction

        protected virtual function void set_max_drop();
            
            void'(reg_block.IRQ.MAX_DROP.predict(1));

            `uvm_info("DEBUG", $sformatf(
                "Drop counter reached max value - %0s: %0d",
                reg_block.IRQEN.MAX_DROP.get_full_name(), 
                reg_block.STATUS.CNT_DROP.get_mirrored_value()
                ),
                UVM_NONE
            )

            if (reg_block.IRQEN.MAX_DROP.get_mirrored_value() == 1) begin
                port_out_irq.write(1);
            end
        endfunction

        protected virtual function void inc_count_drop(cfs_md_response response);

            uvm_reg_data_t max_value = ('h1 << reg_block.STATUS.CNT_DROP.get_n_bits()) - 1; 

            if (response == CFS_MD_OKAY) begin
                return;
            end

            if (reg_block.STATUS.CNT_DROP.get_mirrored_value() < max_value) begin

                begin
                    uvm_reg_data_t current_value = reg_block.STATUS.CNT_DROP.get_mirrored_value();

                    void'(reg_block.STATUS.CNT_DROP.predict(current_value + 1));

                    `uvm_info("DEBUG", 
                        $sformatf(
                            "Increment - %0s: %0d due to %0s",
                            reg_block.STATUS.CNT_DROP.get_full_name(),
                            reg_block.STATUS.CNT_DROP.get_mirrored_value(),
                            response.name()),
                        UVM_NONE

                    )
                end

                if (reg_block.STATUS.CNT_DROP.get_mirrored_value() == max_value) begin
                    this.set_max_drop();
                    return;
                end

            end
        endfunction

         virtual function void kill_process(ref process p);
            if (p != null) begin
                p.kill();

                p = null;
            end
        endfunction

        // ----------------------------------- RX FIFO -----------------------------------
       
        protected virtual function void set_rx_fifo_full();
            fork 
                begin
                    process_set_rx_fifo_full = process::self();

                    repeat(2) begin
                        uvm_wait_for_nba_region();
                    end

                     void'(reg_block.IRQ.RX_FIFO_FULL.predict(1));

                `uvm_info("DEBUG", $sformatf(
                    "RX FIFO is full - %0s: %0d",
                    reg_block.IRQEN.RX_FIFO_FULL.get_full_name(), 
                    reg_block.STATUS.RX_LVL.get_mirrored_value()
                    ),
                    UVM_NONE
                )

                if (reg_block.IRQEN.RX_FIFO_FULL.get_mirrored_value() == 1) begin
                    port_out_irq.write(1);
                end

                end
            join_none 
        endfunction

        protected virtual function void inc_rx_lvl();
            int current_value = reg_block.STATUS.RX_LVL.get_mirrored_value();
            void'(reg_block.STATUS.RX_LVL.predict(current_value + 1));

            if (reg_block.STATUS.RX_LVL.get_mirrored_value() == rx_fifo.size()) begin
                set_rx_fifo_full();
            end
        endfunction

        protected virtual task push_to_rx_fifo(cfs_md_item_mon item_mon);
            
            sync_push_to_rx_fifo();
            
            rx_fifo.put(item_mon);

            kill_set_rx_fifo_empty();

            inc_rx_lvl();

            `uvm_info("DEBUG", $sformatf(
                "Rx Fifo push - new_level: %d, pushed_entry: %0s",
                reg_block.STATUS.RX_LVL.get_mirrored_value(),
                item_mon.convert2string()),
                UVM_NONE 
            )

            port_out_rx.write(CFS_MD_OKAY);
        endtask

        // nb means Non-Blocking
        local virtual function void push_to_rx_fifo_nb(cfs_md_item_mon item);
            if (process_push_to_rx_fifo != null) begin
                `uvm_fatal("ALGORITHM_ISSUE", 
                    "Cannot start two instances of \"push_to_rx_fifo()\" task")
            end

            fork 
                begin 
                    process_push_to_rx_fifo = process::self();

                    push_to_rx_fifo(item);

                    process_push_to_rx_fifo = null;
                end 
            join_none
        endfunction 

        protected virtual function void kill_set_rx_fifo_empty();
            fork 
                begin
                    // Wait one time unit
                    // This can be used ONLY if the two processes are on the same clock
                    uvm_wait_for_nba_region();

                    kill_process(process_set_rx_fifo_empty);
                end
            join_none
        endfunction

        protected virtual task sync_push_to_rx_fifo();
            cfs_algn_vif vif = env_config.get_vif();

            fork
                begin
                    fork
                        begin 
                            @(posedge vif.clk iff(vif.rx_fifo_push));
                        end
                        begin
                            repeat(10) begin
                                @(posedge vif.clk iff(
                                    reg_block.STATUS.RX_LVL.get_mirrored_value() < rx_fifo.size())
                                );
                            end

                            // This could also be error
                            `uvm_warning("DUT_WARNING", "RX FIFO push did not synchronize with RTL")
                        end
                    join_any

                    disable fork;
                end
            join
        endtask
        // ----------------------------------- BUFFER LOGIC -----------------------------------
        
        protected virtual function void set_rx_fifo_empty();
            fork 
                begin
                    process_set_rx_fifo_empty = process::self();

                    repeat(2) begin
                        uvm_wait_for_nba_region();
                    end

                    void'(reg_block.IRQ.RX_FIFO_EMPTY.predict(1));

                    `uvm_info("DEBUG", $sformatf(
                        "RX FIFO is empty - %0s: %0d",
                        reg_block.IRQEN.RX_FIFO_EMPTY.get_full_name(), 
                        reg_block.IRQEN.RX_FIFO_EMPTY.get_mirrored_value()
                        ),
                        UVM_NONE
                    )

                    if (reg_block.IRQEN.RX_FIFO_EMPTY.get_mirrored_value() == 1) begin
                        port_out_irq.write(1);
                    end

                end
            join_none
        endfunction

        protected virtual function void dec_rx_lvl();
            int current_value = reg_block.STATUS.RX_LVL.get_mirrored_value();
            
            void'(reg_block.STATUS.RX_LVL.predict(current_value - 1));

            if (reg_block.STATUS.RX_LVL.get_mirrored_value() == 0) begin
                set_rx_fifo_empty();
            end

        endfunction

        protected virtual task pop_from_rx_fifo(ref cfs_md_item_mon item);
            
            sync_pop_to_rx_fifo();

            rx_fifo.get(item);

            kill_set_rx_fifo_full();

            dec_rx_lvl();

            `uvm_info("DEBUG", $sformatf(
                "Rx Fifo pop - new_level: %d, popped_entry: %0s",
                reg_block.STATUS.RX_LVL.get_mirrored_value(),
                item.convert2string()),
                UVM_NONE 
            )
        endtask

        protected virtual task build_buffer();
            cfs_algn_vif vif = env_config.get_vif();

            forever begin
                int ctrl_size = reg_block.CTRL.SIZE.get_mirrored_value();

                if((buffer.sum() with (item.data.size())) <= ctrl_size) begin
                    cfs_md_item_mon rx_item;

                    pop_from_rx_fifo(rx_item);

                    buffer.push_back(rx_item);
                end else begin
                    @(posedge vif.clk);
                end
            end
        endtask

        local virtual function void build_buffer_nb();
            if (process_build_buffer != null) begin
                `uvm_fatal("ALGORITHM_ISSUE", 
                    "Cannot start two instances of \"build_buffer()\" task")
            end

            fork 
                begin 
                    process_build_buffer = process::self();

                    build_buffer();

                    process_build_buffer = null;
                end 
            join_none
        endfunction

        protected virtual function void kill_set_rx_fifo_full();
            fork
                begin
                    uvm_wait_for_nba_region();

                    kill_process(process_set_rx_fifo_full);
                end
            join_none
        endfunction 

        protected virtual task sync_pop_to_rx_fifo();
            cfs_algn_vif vif = env_config.get_vif();

            fork
                begin
                    fork
                        begin 
                            @(posedge vif.clk iff(vif.rx_fifo_pop));
                        end
                        begin
                            repeat(10) begin
                                @(posedge vif.clk iff(
                                    // Check if the tx fifo can collect also
                                    (reg_block.STATUS.RX_LVL.get_mirrored_value() > 0) && 
                                    (reg_block.STATUS.TX_LVL.get_mirrored_value() < tx_fifo.size())
                                ));
                            end
                            // This could also be error
                            `uvm_warning("DUT_WARNING", "RX FIFO pop did not synchronize with RTL")
                        end
                    join_any

                    disable fork;
                end
            join
        endtask

        // ----------------------------------- ALIGN -----------------------------------
        protected virtual function void set_tx_fifo_full();
            
            fork
                begin
                    process_set_tx_fifo_full = process::self();

                    repeat(2) begin
                        uvm_wait_for_nba_region();
                    end

                     void'(reg_block.IRQ.TX_FIFO_FULL.predict(1));

                    `uvm_info("DEBUG", $sformatf(
                        "TX FIFO is FULL - %0s: %0d",
                        reg_block.IRQEN.TX_FIFO_FULL.get_full_name(), 
                        reg_block.STATUS.TX_LVL.get_mirrored_value()
                        ),
                        UVM_NONE
                    )

                    if (reg_block.IRQEN.TX_FIFO_FULL.get_mirrored_value() == 1) begin
                        port_out_irq.write(1);
                    end

                end                
            join_none
        endfunction

        protected virtual function void inc_tx_lvl();
            int current_value = reg_block.STATUS.TX_LVL.get_mirrored_value();
            
            void'(reg_block.STATUS.TX_LVL.predict(current_value + 1));

            if (reg_block.STATUS.TX_LVL.get_mirrored_value() == tx_fifo.size()) begin
                set_tx_fifo_full();
            end
        endfunction

        protected virtual task push_to_tx_fifo(cfs_md_item_mon item);
            
            sync_push_to_tx_fifo();

            tx_fifo.put(item);

            kill_set_tx_fifo_empty();

            inc_tx_lvl();

            `uvm_info("DEBUG", $sformatf(
                "Tx Fifo push - new_level: %d, pushed_entry: %0s",
                reg_block.STATUS.TX_LVL.get_mirrored_value(),
                item.convert2string()),
                UVM_NONE 
            )
        endtask

        protected virtual function void split(int unsigned num_bytes, cfs_md_item_mon item, ref cfs_md_item_mon items[$]);
            if (num_bytes >= item.data.size()) begin
                `uvm_fatal("ALGORITHM_ISSUE", 
                    $sformatf("num_bytes - %0d cannot be greater or equal to number of bytes in item data - %0d",
                        num_bytes, item.data.size()))
                return;
            end

            if (num_bytes == 0) begin
                `uvm_fatal("ALGORITHM_ISSUE", "\"num_bytes\" cannot be 0")
                return;
            end

            for (int i = 0; i < 2; i++) begin
                cfs_md_item_mon splitted_item = cfs_md_item_mon::type_id::create("splitted_item", this);

                if (i == 0) begin
                    splitted_item.offset = item.offset;

                    for (int j = 0; j < num_bytes; j++) begin
                        splitted_item.data.push_back(item.data[j]);
                    end
                end else begin
                    splitted_item.offset = item.offset + num_bytes; 

                    for (int j = num_bytes; j < item.data.size(); j++) begin
                        splitted_item.data.push_back(item.data[j]);
                    end
                end

                splitted_item.prev_item_delay   = item.prev_item_delay;
                splitted_item.length            = item.length;
                splitted_item.response          = item.response;

                void'(splitted_item.begin_tr(item.get_begin_time()));

                if(!(item.is_active())) begin
                    splitted_item.end_tr(item.get_end_time());
                end

                items.push_back(splitted_item);

            end
        endfunction

        protected virtual task align();
            cfs_algn_vif vif = env_config.get_vif();

            forever begin
                int unsigned ctrl_size  = reg_block.CTRL.SIZE.get_mirrored_value();
                int unsigned ctrl_offset = reg_block.CTRL.OFFSET.get_mirrored_value();

                uvm_wait_for_nba_region();

                if(ctrl_size <= buffer.sum() with (item.data.size())) begin
                    
                    while(ctrl_size <= buffer.sum() with (item.data.size())) begin
                        cfs_md_item_mon tx_item = cfs_md_item_mon::type_id::create("tx_item", this);

                        tx_item.offset = ctrl_offset;

                        void'(tx_item.begin_tr(buffer[0].get_begin_time()));

                        while(tx_item.data.size() < ctrl_size) begin
                            cfs_md_item_mon buffer_item = buffer.pop_front();

                            if (tx_item.data.size() + buffer_item.data.size() <= ctrl_size) begin
                                foreach(buffer_item.data[idx]) begin
                                    tx_item.data.push_back(buffer_item.data[idx]);
                                end
                            
                            end else begin
                                cfs_md_item_mon items[$];
                                int unsigned num_bytes = ctrl_size - tx_item.data.size();
                                
                                this.split(num_bytes, buffer_item, items);
                                
                                foreach(items[0].data[idx]) begin
                                    tx_item.data.push_back(items[0].data[idx]);
                                end

                                this.buffer.push_front(items[1]);
                            end

                            if(tx_item.data.size() == ctrl_size) begin

                                void'(tx_item.end_tr());
                                push_to_tx_fifo(tx_item);
                        
                            end else begin
                            
                                `uvm_fatal("ALGORITHM_ISSUE", 
                                        $sformatf("TX item size %0d > ctrl_size %0d - split logic error", 
                                            tx_item.data.size(), ctrl_size)
                                    )
                                
                            end

                        end 
                        
                    end
                end else begin
                    @(posedge vif.clk);
                end
            end
        endtask

        local virtual function void align_nb();
             if (process_align != null) begin
                `uvm_fatal("ALGORITHM_ISSUE", 
                    "Cannot start two instances of \"align()\" task")
            end

            fork 
                begin 
                    process_align = process::self();

                    align();

                    process_align = null;
                end 
            join_none
        endfunction
        
        protected virtual function void kill_set_tx_fifo_full();
            fork
                begin
                    uvm_wait_for_nba_region();

                    kill_process(process_set_tx_fifo_full);
                end
            join_none
        endfunction

        protected virtual task sync_push_to_tx_fifo();
            cfs_algn_vif vif = env_config.get_vif();

            fork
                begin
                    fork
                        begin 
                            @(posedge vif.clk iff(vif.tx_fifo_push));
                        end
                        begin
                            repeat(10) begin
                                @(posedge vif.clk iff(
                                    (reg_block.STATUS.TX_LVL.get_mirrored_value() < tx_fifo.size())
                                ));
                            end
                            // This could also be error
                            `uvm_warning("DUT_WARNING", "TX FIFO push did not synchronize with RTL")
                        end
                    join_any

                    disable fork;
                end
            join
        endtask

        // ----------------------------------- TX Contrloller -----------------------------------
        protected virtual function void set_tx_fifo_empty();
            fork 
                begin
                    process_set_tx_fifo_empty = process::self();

                    repeat(2) begin
                        uvm_wait_for_nba_region();
                    end

                    void'(reg_block.IRQ.TX_FIFO_EMPTY.predict(1));

                    `uvm_info("DEBUG", $sformatf(
                        "TX FIFO is EMPTY - %0s: %0d",
                        reg_block.IRQEN.TX_FIFO_EMPTY.get_full_name(), 
                        reg_block.STATUS.TX_LVL.get_mirrored_value()
                        ),
                        UVM_NONE
                    )

                    if (reg_block.IRQEN.TX_FIFO_EMPTY.get_mirrored_value() == 1) begin
                        port_out_irq.write(1);
                    end
                end
            join_none
            
        endfunction

        protected virtual function void dec_tx_lvl();
            int current_value = reg_block.STATUS.TX_LVL.get_mirrored_value();
            
            void'(reg_block.STATUS.TX_LVL.predict(current_value - 1));

            if (reg_block.STATUS.TX_LVL.get_mirrored_value() == 0) begin
                set_tx_fifo_empty();
            end
        endfunction

        protected virtual task pop_from_tx_fifo(ref cfs_md_item_mon item);
            
            sync_pop_to_tx_fifo();

            tx_fifo.get(item);

            kill_set_tx_fifo_full();

            dec_tx_lvl();

            `uvm_info("DEBUG", $sformatf(
                "Tx Fifo pop - new_level: %d, popped_entry: %0s",
                reg_block.STATUS.TX_LVL.get_mirrored_value(),
                item.convert2string()),
                UVM_NONE 
            )
        endtask

        protected virtual task tx_ctrl();
            cfs_md_item_mon item;
            
            forever begin

                pop_from_tx_fifo(item);

                port_out_tx.write(item);

                tx_complete.wait_trigger();
                
            end
        endtask

        local virtual function void tx_ctrl_nb();
            if (process_tx_ctrl != null) begin
                `uvm_fatal("ALGORITHM_ISSUE", 
                    "Cannot start two instances of \"tx_ctrl()\" task")
            end

            fork 
                begin 
                    process_tx_ctrl = process::self();

                    tx_ctrl();

                    process_tx_ctrl = null;
                end 
            join_none
        endfunction

        protected virtual function void kill_set_tx_fifo_empty();
            fork
                begin
                    uvm_wait_for_nba_region();

                    kill_process(process_set_tx_fifo_empty);
                end
            join_none
        endfunction

        protected virtual task sync_pop_to_tx_fifo();
            cfs_algn_vif vif = env_config.get_vif();

            fork
                begin
                    fork
                        begin 
                            @(posedge vif.clk iff(vif.tx_fifo_pop));
                        end
                        begin
                            repeat(200) begin
                                @(posedge vif.clk iff(
                                    (reg_block.STATUS.TX_LVL.get_mirrored_value() > 0)
                                ));
                            end
                              // This could also be error
                            `uvm_warning("DUT_WARNING", "TX FIFO pop did not synchronize with RTL")
                        end
                    join_any

                    disable fork;
                end
            join
        endtask

    endclass

`endif