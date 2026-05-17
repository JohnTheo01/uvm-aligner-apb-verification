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
        
            #(100ns);

            // fork
            //     begin
            //         cfs_md_sequence_slave_response_forever seq_response_forever = 
            //             cfs_md_sequence_slave_response_forever::type_id::create("seq_response_forever");
                    
            //         seq_response_forever.start(env.md_tx_agent.sequencer);
            //     end
            // join_none

            env.model.reg_block.IRQEN.write(status, 5'b11111);

             // 5 APB transactions για testing του recorder
            repeat(5) begin
                cfs_apb_sequence_simple seq;
                seq = cfs_apb_sequence_simple::type_id::create("seq");
                void'(seq.randomize());
                seq.start(env.apb_agent.sequencer);
            end

            void'(env.model.reg_block.CTRL.randomize() with{
                SIZE.value == 2;
                OFFSET.value == 0;
            });
            env.model.reg_block.CTRL.update(status);

           

          
            repeat(8) begin 
                // cfs_md_sequence_simple_master seq_simple = cfs_md_sequence_simple_master::type_id::create("seq_simple");

                // seq_simple.set_sequencer(env.md_rx_agent.sequencer);
                
                // void'(seq_simple.randomize());

                // seq_simple.start(env.md_rx_agent.sequencer);

                cfs_algn_virtual_sequence_slow_pace vseq_slow_pace;
                vseq_slow_pace = cfs_algn_virtual_sequence_slow_pace::type_id::create("vseq_slow_pace");

                vseq_slow_pace.set_sequencer(env.virtual_sequencer);

                void'(vseq_slow_pace.randomize());

                vseq_slow_pace.start(env.virtual_sequencer);

            end
            
            #(500ns);

            phase.drop_objection(this, "TEST_DONE");

        endtask


    endclass
`endif