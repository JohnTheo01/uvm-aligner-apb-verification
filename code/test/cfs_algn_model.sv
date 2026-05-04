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
            `uvm_info("DEBUG", $sformatf(
                "Model received information from the RX agent: %0s", 
                item_mon.convert2string()
                ),
                UVM_NONE
            )
        endfunction

        virtual function void write_in_tx(cfs_md_item_mon item_mon);
            `uvm_info("DEBUG", $sformatf(
                "Model received information from the TX agent: %0s", 
                item_mon.convert2string()
                ),
                UVM_NONE
            )
        endfunction

    endclass

`endif