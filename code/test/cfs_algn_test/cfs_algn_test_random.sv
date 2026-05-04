`ifndef CFS_ALGN_TEST_RANDOM

    `define CFS_ALGN_TEST_RANDOM

    class cfs_algn_test_random 
        extends cfs_algn_test_base;

        `uvm_component_utils(cfs_algn_test_random)

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        virtual task run_phase(uvm_phase phase);
            uvm_status_e status;
    
            phase.raise_objection(this, "TEST_DONE");

            `uvm_info("DEBUG", "start of test", UVM_LOW)

        
            #(100ns);

            fork
                begin
                    cfs_md_sequence_slave_response_forever seq_response_forever = 
                        cfs_md_sequence_slave_response_forever::type_id::create("seq_response_forever");
                    
                    seq_response_forever.start(env.md_tx_agent.sequencer);
                end
            join_none

            env.model.reg_block.CTRL.OFFSET.set(1);
            env.model.reg_block.CTRL.SIZE.set(1);
            env.model.reg_block.CTRL.update(status);

            repeat(2) begin 
                cfs_md_sequence_simple_master seq_simple = cfs_md_sequence_simple_master::type_id::create("seq_simple");

                seq_simple.set_sequencer(env.md_rx_agent.sequencer);
                
                void'(seq_simple.randomize() with {
                    item.data.size() == 3;
                    item.offset == 0;
                });

                seq_simple.start(env.md_rx_agent.sequencer);
            end

            repeat(2) begin 
                cfs_md_sequence_simple_master seq_simple = cfs_md_sequence_simple_master::type_id::create("seq_simple");

                seq_simple.set_sequencer(env.md_rx_agent.sequencer);
                
                void'(seq_simple.randomize() with {
                    item.data.size() == 4;
                    item.offset == 0;
                });

                seq_simple.start(env.md_rx_agent.sequencer);
            end

            // repeat(20) begin 
            //     cfs_md_sequence_simple_master seq_simple = cfs_md_sequence_simple_master::type_id::create("seq_simple");

            //     seq_simple.set_sequencer(env.md_rx_agent.sequencer);
                
            //     void'(seq_simple.randomize() with {
                   
            //     });

            //     seq_simple.start(env.md_rx_agent.sequencer);
            // end
            
            #(100ns);

            `uvm_info("DEBUG", "end of test", UVM_LOW)

            phase.drop_objection(this, "TEST_DONE");

        endtask


    endclass
`endif