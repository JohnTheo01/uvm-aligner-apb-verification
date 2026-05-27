`ifndef CFS_ALGN_VIRTUAL_SEQUENCE_RX_SV

    `define CFS_ALGN_VIRTUAL_SEQUENCE_RX_SV

    class cfs_algn_virtual_sequence_rx
        extends cfs_algn_virtual_sequence_base;

        rand cfs_md_sequence_simple_master seq;

        `uvm_object_utils(cfs_algn_virtual_sequence_rx)

        function new(string name = "");
            super.new(name);

            seq = cfs_md_sequence_simple_master::type_id::create("seq");
        endfunction

        function void pre_randomize();
            super.pre_randomize();

            seq.set_sequencer(p_sequencer.md_rx_sequencer);
        endfunction

        virtual task body();
            seq.start(p_sequencer.md_rx_sequencer);
        endtask
    endclass

`endif