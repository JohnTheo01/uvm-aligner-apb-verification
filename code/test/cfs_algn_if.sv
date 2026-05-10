`ifndef CFS_ALGN_IF_SV

    `define CFS_ALGN_IF_SV

    interface cfs_algn_if(input clk);
        
        logic reset_n;

        logic irq;
    endinterface

`endif
