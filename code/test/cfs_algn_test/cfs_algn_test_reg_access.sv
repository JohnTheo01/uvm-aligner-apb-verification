`ifndef CFS_ALGN_TEST_REG_ACCESS_SV

    `define CFS_ALGN_TEST_REG_ACCESS_SV

    `include "uvm_macros.svh"

    class cfs_algn_test_reg_access extends cfs_algn_test_base;

        // Number of register accesses
        protected int unsigned num_reg_accesses;

        // Number of unmapped accesses
        protected int unsigned num_unmapped_accesses;

        `uvm_component_utils(cfs_algn_test_reg_access)

        function new(string name, uvm_component parent);
            super.new(name, parent);

            this.num_reg_accesses = 100;
            this.num_unmapped_accesses = 100;
        endfunction

        virtual task run_phase(uvm_phase phase);
    
            uvm_status_e status;
            uvm_reg_data_t data;

            phase.raise_objection(this, "TEST_DONE");


            fork 
                begin : DRIVE_REG_ACCESS
                    // Drive register accesses
                    cfs_algn_virtual_sequence_reg_access_random seq = cfs_algn_virtual_sequence_reg_access_random::type_id::create("seq");

                    void'(seq.randomize() with {
                        num_accesses == num_reg_accesses;
                    });

                    seq.start(env.virtual_sequencer);
                end
                begin : DRIVE_UNMAPPED_ACCESS
                    // Drive APB accesses to unmapped locations
                    cfs_algn_virtual_sequence_unmapped_access seq = cfs_algn_virtual_sequence_unmapped_access::type_id::create("seq");

                    void'(seq.randomize() with {
                        num_accesses == num_unmapped_accesses;
                    });

                    seq.start(env.virtual_sequencer);
                end
            join
            phase.drop_objection(this, "TEST_DONE");

        endtask

    endclass

`endif