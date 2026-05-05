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

        `uvm_component_utils(cfs_algn_model)

        function new(string name = "", uvm_component parent);
            super.new(name, parent);

            port_in_rx = new("port_in_rx", this);
            port_in_tx = new("port_in_tx", this);

            port_out_rx = new("port_out_rx", this);
            port_out_tx = new("port_out_tx", this);

            port_out_irq = new("port_out_irq", this);

            rx_fifo = new("rx_fifo", this, 8);
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

            rx_fifo.flush();
            buffer = {};

            build_buffer_nb();
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
            `uvm_info("DEBUG", $sformatf(
                "Model received information from the TX agent: %0s", 
                item_mon.convert2string()
                ),
                UVM_NONE
            )
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

            if (reg_block.STATUS.CNT_DROP.get_mirrored_value() == max_value) begin
                this.set_max_drop();
                return;
            end

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

        endfunction

         virtual function void kill_process(ref process p);
            if (p != null) begin
                p.kill();

                p = null;
            end

        endfunction

        // ----------------------------------- RX FIFO -----------------------------------
       

        protected virtual function void set_rx_fifo_full();
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
        endfunction

        protected virtual function void inc_rx_lvl();
            int current_value = reg_block.STATUS.RX_LVL.get_mirrored_value();
            void'(reg_block.STATUS.RX_LVL.predict(current_value + 1));

            if (reg_block.STATUS.RX_LVL.get_mirrored_value() == rx_fifo.size()) begin
                set_rx_fifo_full();
            end
        endfunction

        protected virtual task push_to_rx_fifo(cfs_md_item_mon item_mon);
            rx_fifo.put(item_mon);

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

        // ----------------------------------- BUFFER LOGIC -----------------------------------
        
        protected virtual function void set_rx_fifo_empty();
            void'(reg_block.IRQ.RX_FIFO_EMPTY.predict(1));

            `uvm_info("DEBUG", $sformatf(
                "RX FIFO is empty - %0s: %0d",
                reg_block.IRQEN.RX_FIFO_EMPTY.get_full_name(), 
                reg_block.STATUS.RX_LVL.get_mirrored_value()
                ),
                UVM_NONE
            )

            if (reg_block.IRQEN.RX_FIFO_EMPTY.get_mirrored_value() == 1) begin
                port_out_irq.write(1);
            end
        endfunction

        protected virtual function void dec_rx_lvl();
            int current_value = reg_block.STATUS.RX_LVL.get_mirrored_value();
            
            void'(reg_block.STATUS.RX_LVL.predict(current_value - 1));

            if (reg_block.STATUS.RX_LVL.get_mirrored_value() == 0) begin
                set_rx_fifo_empty();
            end

        endfunction

        protected virtual task pop_from_rx_fifo(ref cfs_md_item_mon item);
             rx_fifo.get(item);

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

        protected virtual function void build_buffer_nb();
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

    endclass

`endif