`ifndef CFS_ALGN_TEST_RANDOM

    `define CFS_ALGN_TEST_RANDOM

    class cfs_algn_test_random 
        extends cfs_algn_test_base;

        protected int unsigned num_random_transactions;

        `uvm_component_utils(cfs_algn_test_random)

        function new(string name, uvm_component parent);
            super.new(name, parent);

            this.num_random_transactions = 100;
        endfunction

        virtual task run_phase(uvm_phase phase);
            uvm_status_e status;
    
            phase.raise_objection(this, "TEST_DONE");
        
            #(100ns);

            fork 
                begin
                    cfs_md_sequence_slave_response_forever seq = cfs_md_sequence_slave_response_forever::type_id::create("seq");

                    seq.start(env.md_tx_agent.sequencer);
                end 
            join_none

            // Write random values to all registers
            repeat(2) begin
                if (env.env_config.model.is_empty() == 1) begin
                    begin: WRITE_TO_REGISTERS
                        cfs_algn_virtual_sequence_reg_config seq = cfs_algn_virtual_sequence_reg_config::type_id::create("seq");

                        void'(seq.randomize());

                        seq.start(env.virtual_sequencer);
                    end
                end
            
                    // Drive random traffic
                    repeat(this.num_random_transactions) begin : DRIVE_RX_TRANSACTIONS
                        cfs_algn_virtual_sequence_rx seq = cfs_algn_virtual_sequence_rx::type_id::create("seq");

                        seq.set_sequencer(env.virtual_sequencer);

                        void'(seq.randomize());

                        seq.start(env.virtual_sequencer);
                    end

                    // We wait for data to be handled from rtl so that status registers don't change
                    begin : WAIT_RTL_TO_FINISH_WITH_DATA
                        cfs_algn_vif vif = env.env_config.get_vif();

                        repeat(100) begin
                            @(posedge vif.clk);
                        end
                    end

                    // Read status register
                    begin: READ_STATUS_REG 
                        cfs_algn_virtual_sequence_reg_status seq = cfs_algn_virtual_sequence_reg_status::type_id::create("seq");

                        void'(seq.randomize());

                        seq.start(env.virtual_sequencer);
                end
                
            end

            #(100ns);

            phase.drop_objection(this, "TEST_DONE");

        endtask


    endclass
`endif