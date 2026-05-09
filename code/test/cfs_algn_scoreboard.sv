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
        implements uvm_ext_reset_handler;

        // ----------------------------------- Env configuration -----------------------------------
        cfs_algn_env_config env_config;

        // ----------------------------------- Model Input ports -----------------------------------
        uvm_analysis_imp_in_model_rx#( cfs_md_response, cfs_algn_scoreboard) port_in_model_rx;
        uvm_analysis_imp_in_model_tx#( cfs_md_item_mon, cfs_algn_scoreboard) port_in_model_tx;
        uvm_analysis_imp_in_model_irq#(bit            , cfs_algn_scoreboard) port_in_model_irq;

        // ----------------------------------- Agent Input ports -----------------------------------
        uvm_analysis_imp_in_agent_rx#( cfs_md_item_mon, cfs_algn_scoreboard) port_in_agent_rx;
        uvm_analysis_imp_in_agent_tx#( cfs_md_item_mon, cfs_algn_scoreboard) port_in_agent_tx;

        // ----------------------------------- Exp Responses -----------------------------------
        protected cfs_md_response exp_rx_response[$];
        local process process_exp_rx_response_watch_dog[$];

        protected cfs_md_item_mon exp_tx_items[$];
        local process process_exp_tx_items_watch_dog[$];

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
            exp_rx_response.delete();
            exp_tx_items.delete();

            kill_processes_from_queue(process_exp_rx_response_watch_dog);
            kill_processes_from_queue(process_exp_tx_items_watch_dog);
        endfunction

        protected virtual function void kill_processes_from_queue(ref process processes[$]);
            int size = processes.size();

            for (int i = size - 1; i >= 0; i--) begin
                processes[i].kill();
                void'(processes.pop_back());
            end
        endfunction

        // ----------------------------------- Model Writing Ports -----------------------------------
        virtual function void write_in_model_rx(cfs_md_response response);
            if (exp_rx_response.size() >= 1) begin
                `uvm_fatal("ALGORITHM_ISSUE", 
                    $sformatf("There are already %0d entries in exp_rx_response",
                        exp_rx_response.size())
                )
            end

            exp_rx_response.push_back(response);

            exp_rx_response_watchdog_nb(response);
        endfunction

        virtual function void write_in_model_tx(cfs_md_item_mon item);
             if (exp_tx_items.size() >= 1) begin
                `uvm_fatal("ALGORITHM_ISSUE", 
                    $sformatf("There are already %0d entries in exp_tx_items",
                        exp_rx_response.size())
                )
            end

            exp_tx_items.push_back(item);

            exp_tx_items_watchdog_nb(item);
        endfunction

        virtual function void write_in_model_irq(bit irq);

        endfunction

        // ----------------------------------- Agent Writing Ports -----------------------------------

        virtual function void write_in_agent_rx(cfs_md_item_mon item_mon);
            if (item_mon.is_active() == 0) begin
                cfs_md_response exp_response;

                if (exp_rx_response.size() == 0) begin
                    `uvm_error("DUT_ERROR", "Unexpected RX response")
                    return;
                end

                exp_response = exp_rx_response.pop_front();

                process_exp_rx_response_watch_dog[0].kill();

                void'(process_exp_rx_response_watch_dog.pop_front());

                if (env_config.get_has_checks()) begin
                    if (item_mon.response != exp_response) begin
                        `uvm_error("DUT_ERROR", 
                            $sformatf("Mismatch detected for the RX response -> expected: %0s, received: %0s, item: %0s",
                                exp_response.name(), item_mon.response.name(), item_mon.convert2string()
                            )
                        )
                    end
                end
            end
        endfunction

        virtual function void write_in_agent_tx(cfs_md_item_mon item_mon);
            cfs_md_item_mon exp_item;

            if (item_mon.is_active()) begin
                return;
            end
            

            if (exp_tx_items.size() == 0) begin
                `uvm_error("DUT_ERROR", "Unexpected TX item")
                return;
            end
            
            exp_item = exp_tx_items.pop_front();

            process_exp_tx_items_watch_dog[0].kill();

            void'(process_exp_tx_items_watch_dog.pop_front());

            if (env_config.get_has_checks()) begin

                if (
                    (item_mon.offset != exp_item.offset)            ||
                    (item_mon.data.size() != exp_item.data.size())  ||
                    (item_mon.data != exp_item.data)
                ) begin
                    `uvm_error("DUT_ERROR", 
                        $sformatf("Mismatch detected for the TX items -> expected: %0s, received: %0s",
                            exp_item.convert2string(), item_mon.convert2string()
                        )
                    )
                end

            end
            
            
        endfunction


        // -----------------------------------  Rx exp -----------------------------------
        protected virtual task exp_rx_response_watchdog(cfs_md_response response);
            
            cfs_algn_vif vif        = env_config.get_vif();
            int unsigned threshold  = env_config.get_exp_rx_response_threshold();
            time start_time         = $time();

            repeat(threshold) begin
                @(posedge vif.clk);
            end

            if (env_config.get_has_checks()) begin
                `uvm_error("DUT_ERROR", 
                    $sformatf(
                        "The RX response, with value %0s, expected from time %0t was not received after %0d clock cycles",
                        response.name(), start_time, threshold
                    )
                )
            end
        endtask

        local function void exp_rx_response_watchdog_nb(cfs_md_response response);
            fork 
                begin
                    process_exp_rx_response_watch_dog.push_back(process::self());

                    exp_rx_response_watchdog(response);

                    if (process_exp_rx_response_watch_dog.size() == 0) begin
                        `uvm_fatal(
                            "ALGORITHM_ISSUE", 
                            "At the end of task exp_rx_response_watchdog() the queue of processes process_exp_rx_response_watch_dog is empty"
                        )
                    end

                    void'(process_exp_rx_response_watch_dog.pop_front());                    

                end 
            join_none
        endfunction

        // ----------------------------------- Exp TX Response -----------------------------------
        protected virtual task exp_tx_items_watchdog(cfs_md_item_mon item_mon);
            cfs_algn_vif vif        = env_config.get_vif();
            int unsigned threshold  = env_config.get_exp_tx_items_threshold();
            time start_time         = $time();

            repeat(threshold) begin
                @(posedge vif.clk);
            end

            if (env_config.get_has_checks()) begin
                `uvm_error("DUT_ERROR", 
                    $sformatf(
                        "The TX item: %0s, expected from time %0t was not received after %0d clock cycles",
                        item_mon.convert2string(), start_time, threshold
                    )
                )
            end

        endtask

        local function void exp_tx_items_watchdog_nb(cfs_md_item_mon item_mon);
            fork 
                begin
                    process_exp_tx_items_watch_dog.push_back(process::self());

                    exp_tx_items_watchdog(item_mon);

                    if (process_exp_tx_items_watch_dog.size() == 0) begin
                        `uvm_fatal(
                            "ALGORITHM_ISSUE", 
                            "At the end of task exp_rx_response_watchdog() the queue of processes process_exp_tx_items_watch_dog is empty"
                        )
                    end

                    void'(process_exp_tx_items_watch_dog.pop_front());                    

                end 
            join_none
        endfunction

    endclass

`endif
