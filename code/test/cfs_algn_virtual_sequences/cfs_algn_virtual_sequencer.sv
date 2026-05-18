`ifndef CFS_ALGN_VIRTUAL_SEQUENCER_SV

    `define CFS_ALGN_VIRTUAL_SEQUENCER_SV

    class cfs_algn_virtual_sequencer
        extends uvm_sequencer;

        uvm_sequencer_base apb_sequencer;

        cfs_md_sequencer_base_master md_rx_sequencer;
        cfs_md_sequencer_base_slave  md_tx_sequencer;

        cfs_algn_model model;

        `uvm_component_utils(cfs_algn_virtual_sequencer)

        function new(string name = "", uvm_component parent);
            super.new(name, parent);
        endfunction

    endclass

`endif
