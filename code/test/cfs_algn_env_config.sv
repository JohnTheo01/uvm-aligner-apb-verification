`ifndef CFS_ALGN_ENV_CONFIG_SV

    `define CFS_ALGN_ENV_CONFIG_SV

    class cfs_algn_env_config
        extends uvm_component;

        protected cfs_algn_vif vif;

        local bit has_checks;

        local int unsigned algn_data_width;

        local int unsigned exp_rx_response_threshold;

        `uvm_component_utils(cfs_algn_env_config)

        function new(string name = "", uvm_component parent);
            super.new(name, parent);

            has_checks = 1;
            algn_data_width = 8;
            exp_rx_response_threshold = 10;
        endfunction

        virtual function void start_of_simulation_phase(uvm_phase phase);
            super.start_of_simulation_phase(phase);
        
            if (this.vif == null) begin
                `uvm_fatal("ALGORITHM_ISSUE", "Virtual Interface has not been instantiated in \"start_of_simulation_phase\" phase")
            end else begin
                `uvm_info("DEBUG", "Virtual Interface has been instantiated in \"start_of_simulation_phase\" phase", UVM_DEBUG)
            end

        endfunction

        // ----------------------------------- Setters - Getters -----------------------------------

        // ----------------------------------- has_checks -----------------------------------
        virtual function bit get_has_checks();
            return this.has_checks;
        endfunction

        virtual function void set_has_checks(bit value);
            this.has_checks = value;
        endfunction

        // ----------------------------------- align_data_width -----------------------------------
        virtual function int unsigned get_algn_data_width();
            return this.algn_data_width;
        endfunction

        virtual function void set_algn_data_width(int unsigned value);
            if ((value < 8) || ($countones(value) != 1)) begin
                `uvm_fatal("ALGORITHM_ISSUE", "You need to specify correct values for \"algn_data_width\"")
            end 
            this.algn_data_width = value;
        endfunction

        // ----------------------------------- vif -----------------------------------
        virtual function void set_vif(cfs_algn_vif value);
            if (this.vif == null) begin
                this.vif = value;
                return;
            end

            `uvm_fatal("ALGORITHM_ISSUE", "Trying to set the virtual interface more than once")
        endfunction

        virtual function cfs_algn_vif get_vif();
            return this.vif;
        endfunction

      
        // ----------------------------------- exp_rx_respnse_threshold -----------------------------------
        virtual function void set_exp_rx_respnse_threshold(int unsigned value);
            this.exp_rx_response_threshold = value;
        endfunction

        virtual function int unsigned get_exp_rx_respnse_threshold();
            return this.exp_rx_response_threshold;
        endfunction

    endclass

`endif 