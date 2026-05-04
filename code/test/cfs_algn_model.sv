`ifndef CFS_ALGN_MODEL_SV

    `define CFS_ALGN_MODEL_SV

    `uvm_analysis_imp_decl(_in_rx)
    `uvm_analysis_imp_decl(_in_tx)

    class cfs_algn_model 
        extends uvm_component
        implements uvm_ext_reset_handler;

        `uvm_component_utils(cfs_algn_model)

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

        function new(string name = "", uvm_component parent);
            super.new(name, parent);

            port_in_rx = new("port_in_rx", this);
            port_in_tx = new("port_in_tx", this);

            port_out_rx = new("port_out_rx", this);
            port_out_tx = new("port_out_tx", this);

            port_out_irq = new("port_out_irq", this);
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

        virtual function void handle_reset(uvm_phase phase);
            reg_block.reset("HARD");
        endfunction

        virtual function void write_in_rx(cfs_md_item_mon item_mon);
            cfs_md_response response;

            if (item_mon.is_active() == 0) begin
                return;
            end

            response = this.get_exp_response(item_mon);

            case (response) 

                CFS_MD_OKAY: begin
                    // TODO: Fill in                   
                end

                CFS_MD_ERR: begin
                    this.increment_count_drop(response);
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
                reg_block.IRQEN.get_full_name(), 
                reg_block.STATUS.CNT_DROP.get_mirrored_value()
                ),
                UVM_NONE
            )

            if (reg_block.IRQEN.MAX_DROP.get_mirrored_value() == 1) begin
                port_out_irq.write(1);
            end
        endfunction

        protected virtual function void increment_count_drop(cfs_md_response response);

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

    endclass

`endif