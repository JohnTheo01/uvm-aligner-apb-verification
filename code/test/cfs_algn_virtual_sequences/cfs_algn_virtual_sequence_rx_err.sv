`ifndef CFS_ALGN_VIRTUAL_SEQUENCE_RX_ERR_SV

    `define CFS_ALGN_VIRTUAL_SEQUENCE_RX_ERR_SV

    class cfs_algn_virtual_sequence_rx_err
        extends cfs_algn_virtual_sequence_rx;

        local int unsigned alng_data_width;

        constraint illegal_rx_hard {
            (((alng_data_width / 8) + seq.item.offset) % seq.item.data.size() != 0) ||
            (seq.item.offset + seq.item.data.size() > (alng_data_width/8));
        }

        `uvm_object_utils(cfs_algn_virtual_sequence_rx_err)

        function new(string name = "");
            super.new(name);
        endfunction

        function void pre_randomize();
            super.pre_randomize();

            alng_data_width = p_sequencer.model.env_config.get_algn_data_width();
        endfunction

    endclass
`endif