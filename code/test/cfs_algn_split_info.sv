`ifndef CFS_ALGN_SPLIT_INFO_SV

    `define CFS_ALGN_SPLIT_INFO_SV

    class cfs_algn_split_info extends uvm_object;

        int unsigned ctrl_offset;

        int unsigned ctrl_size;

        int unsigned md_offset;

        int unsigned md_size;

        int unsigned num_bytes_needed;

        `uvm_object_utils(cfs_algn_split_info)

        function new(string name = "");
            super.new(name);
        endfunction

    endclass
`endif
