`ifndef CFS_ALGN_SCOREBOARD_SV

    `define CFS_ALGN_SCOREBOARD_SV
    
    // ----------------------------------- Model Input ports -----------------------------------
    `uvm_analysis_imp_decl(_in_model_rx)
    `uvm_analysis_imp_decl(_in_model_tx)
    `uvm_analysis_imp_decl(_in_model_irq)

    // ----------------------------------- Agent Input ports -----------------------------------
    `uvm_analysis_imp_decl(_in_agent_rx)
    `uvm_analysis_imp_decl(_in_agent_tx)


    class cfs_algn_scoreboard 
        extends uvm_component
        implements uvm_ext_reset_handler

        // ----------------------------------- Env configuration -----------------------------------
        cfs_algn_env_config env_config;

        // ----------------------------------- Model Input ports -----------------------------------
        uvm_analysis_impl_in_model_rx#( cfs_md_response, cfs_algn_scoreboard) port_in_model_rx;
        uvm_analysis_impl_in_model_tx#( cfs_md_item_mon, cfs_algn_scoreboard) port_in_model_tx;
        uvm_analysis_impl_in_model_irq#(bit            , cfs_algn_scoreboard) port_in_model_irq;

        // ----------------------------------- Agent Input ports -----------------------------------
        uvm_analysis_impl_in_agent_rx#( cfs_md_response, cfs_algn_scoreboard) port_in_agent_rx;
        uvm_analysis_impl_in_agent_tx#( cfs_md_item_mon, cfs_algn_scoreboard) port_in_agent_tx;

        `uvm_component_utils(cfs_algn_scoreboard)

        function new(string name = "", uvm_component parent);
            super.new(name, parent);

            port_in_model_rx    = new("port_in_model_rx",  this);
            port_in_model_tx    = new("port_in_model_tx",  this);
            port_in_model_irq   = new("port_in_model_irq", this);
            port_in_agent_rx    = new("port_in_agent_rx",  this);
            port_in_agent_tx    = new("port_in_agent_tx",  this);
        endfunction

        // ----------------------------------- RESET LOGIC -----------------------------------
        virtual function void handle_reset(uvm_phase phase);

        endfunction

        // ----------------------------------- Model Writing Ports -----------------------------------
        virtual function void write_in_model_rx(cfs_md_response response);

        endfunction

        virtual function void write_in_model_tx(cfs_md_item_mon item);

        endfunction

        virtual function void write_in_model_irq(bit irq);

        endfunction

        // ----------------------------------- Agent Writing Ports -----------------------------------

        virtual function void write_in_agent_rx(cfs_md_item_mon item);

        endfunction

        virtual function void write_in_agent_tx(cfs_md_item_mon item);

        endfunction



    endclass

`endif
