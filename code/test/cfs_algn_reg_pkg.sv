`ifndef CFS_ALGN_REG_PKG_SV

    `define CFS_ALGN_REG_PKG_SV

    `include "uvm_ext_pkg.sv"

    package cfs_algn_reg_pkg;
        import uvm_pkg::*;
        import uvm_ext_pkg::*;

        class cfs_algn_reg_ctrl extends uvm_reg;

            // ----------------------------------- REG FIELDS -----------------------------------
            rand uvm_reg_field SIZE;

            rand uvm_reg_field OFFSET;

            rand uvm_reg_field CLR;

            local int unsigned ALGN_DATA_WIDTH;

            // ----------------------------------- CONSTRAINTS -----------------------------------
            constraint legal_size {
                SIZE.value != 0;
            }

            constraint legal_combination_size_offset{
                ((ALGN_DATA_WIDTH / 8) + OFFSET.value) % SIZE.value == 0;
                OFFSET.value + SIZE.value <= (ALGN_DATA_WIDTH / 8);
            }

            // ----------------------------------- BOILERPLATE CODE  -----------------------------------
            `uvm_object_utils(cfs_algn_reg_ctrl)

            function new(string name = "");
                super.new(name, .n_bits(32), .has_coverage(UVM_NO_COVERAGE));

                this.ALGN_DATA_WIDTH = 8;
            endfunction

            virtual function void build();
                SIZE    = uvm_reg_field::type_id::create("SIZE", null, get_full_name());
                OFFSET  = uvm_reg_field::type_id::create("OFFSET", null, get_full_name());
                CLR     = uvm_reg_field::type_id::create("CLR", null, get_full_name());


                SIZE.configure(
                    .parent(this),
                    .size(3),
                    .lsb_pos(0),
                    .access("RW"),
                    .volatile(0),
                    .reset(3'b001),
                    .has_reset(1),
                    .is_rand(1),
                    .individually_accessible(0)
                );

                OFFSET.configure(
                    .parent(this),
                    .size(2),
                    .lsb_pos(8),
                    .access("RW"),
                    .volatile(0),
                    .reset(2'b00),
                    .has_reset(1),
                    .is_rand(1),
                    .individually_accessible(0)
                );

                CLR.configure(
                    .parent(this),
                    .size(1),
                    .lsb_pos(16),
                    .access("WO"),
                    .volatile(0),
                    .reset(1'b0),
                    .has_reset(1),
                    .is_rand(1),
                    .individually_accessible(0)
                );

            endfunction

            virtual function void set_algn_data_width(int unsigned value);
                 if ((value < 8) || ($countones(value) != 1)) begin
                    `uvm_fatal("ALGORITHM_ISSUE", "You need to specify correct values for \"algn_data_width\"")
                end

                this.ALGN_DATA_WIDTH = value;
            endfunction

            virtual function int unsigned get_algn_data_width();
                return this.ALGN_DATA_WIDTH;
            endfunction

        endclass

        class cfs_algn_reg_status extends uvm_reg;

            rand uvm_reg_field CNT_DROP;

            rand uvm_reg_field RX_LVL;

            rand uvm_reg_field TX_LVL;

            `uvm_object_utils(cfs_algn_reg_status)

            function new(string name = "");
                super.new(name, 32, UVM_NO_COVERAGE);
            endfunction

            virtual function void build();
                CNT_DROP    = uvm_reg_field::type_id::create("CNT_DROP", null, get_full_name());
                RX_LVL      = uvm_reg_field::type_id::create("RX_LVL", null, get_full_name());
                TX_LVL      = uvm_reg_field::type_id::create("TX_LVL", null, get_full_name());

                CNT_DROP.configure(
                    .parent(this),
                    .size(8),
                    .lsb_pos(0),
                    .access("RO"),
                    .volatile(0),
                    .reset(8'b00000000),
                    .has_reset(1),
                    .is_rand(1),
                    .individually_accessible(0)
                );

                RX_LVL.configure(
                    .parent(this),
                    .size(4),
                    .lsb_pos(8),
                    .access("RO"),
                    .volatile(0),
                    .reset(4'b0000),
                    .has_reset(1),
                    .is_rand(1),
                    .individually_accessible(0)
                );


                TX_LVL.configure(
                    .parent(this),
                    .size(4),
                    .lsb_pos(16),
                    .access("RO"),
                    .volatile(0),
                    .reset(4'b0000),
                    .has_reset(1),
                    .is_rand(1),
                    .individually_accessible(0)
                );


            endfunction

        endclass

        class cfs_algn_reg_irqen extends uvm_reg;

            rand uvm_reg_field RX_FIFO_EMPTY;
            rand uvm_reg_field RX_FIFO_FULL;
            rand uvm_reg_field TX_FIFO_EMPTY;
            rand uvm_reg_field TX_FIFO_FULL;
            rand uvm_reg_field MAX_DROP;

            `uvm_object_utils(cfs_algn_reg_irqen)

            function new(string name = "");
                super.new(name, 32, UVM_NO_COVERAGE);
            endfunction

            virtual function void build();
                RX_FIFO_FULL    = uvm_reg_field::type_id::create("RX_FIFO_FULL", null, get_full_name());
                RX_FIFO_EMPTY   = uvm_reg_field::type_id::create("RX_FIFO_EMPTY", null, get_full_name());
                TX_FIFO_EMPTY   = uvm_reg_field::type_id::create("TX_FIFO_EMPTY", null, get_full_name());
                TX_FIFO_FULL    = uvm_reg_field::type_id::create("TX_FIFO_FULL", null, get_full_name());
                MAX_DROP        = uvm_reg_field::type_id::create("MAX_DROP", null, get_full_name());

                RX_FIFO_EMPTY.configure(
                    .parent(this),
                    .size(1),
                    .lsb_pos(0),
                    .access("RW"),
                    .volatile(0),
                    .reset(1'b0),
                    .has_reset(1),
                    .is_rand(1),
                    .individually_accessible(0)
                );

                RX_FIFO_FULL.configure(
                    .parent(this),
                    .size(1),
                    .lsb_pos(1),
                    .access("RW"),
                    .volatile(0),
                    .reset(1'b0),
                    .has_reset(1),
                    .is_rand(1),
                    .individually_accessible(0)
                );

                TX_FIFO_EMPTY.configure(
                    .parent(this),
                    .size(1),
                    .lsb_pos(2),
                    .access("RW"),
                    .volatile(0),
                    .reset(1'b0),
                    .has_reset(1),
                    .is_rand(1),
                    .individually_accessible(0)
                );

                TX_FIFO_FULL.configure(
                    .parent(this),
                    .size(1),
                    .lsb_pos(3),
                    .access("RW"),
                    .volatile(0),
                    .reset(1'b0),
                    .has_reset(1),
                    .is_rand(1),
                    .individually_accessible(0)
                );

                MAX_DROP.configure(
                    .parent(this),
                    .size(1),
                    .lsb_pos(4),
                    .access("RW"),
                    .volatile(0),
                    .reset(1'b0),
                    .has_reset(1),
                    .is_rand(1),
                    .individually_accessible(0)
                );

            endfunction
        endclass

        // =============================================================================
        // AUTO-EDITED by add_uvm_field.py
        // Last edit : 2026-05-02 16:10:57
        // Generated : 2026-05-02 16:08:38
        // Fields    : RX_FIFO_EMPTY, RX_FIFO_FULL, TX_FIFO_EMPTY, TX_FIFO_FULL, MAX_DROP
        // Width     : 32 bits
        // Coverage  : UVM_NO_COVERAGE
        // =============================================================================

        class cfs_algn_reg_irq extends uvm_reg;

            rand uvm_reg_field RX_FIFO_EMPTY;
            rand uvm_reg_field RX_FIFO_FULL;
            rand uvm_reg_field TX_FIFO_EMPTY;
            rand uvm_reg_field TX_FIFO_FULL;
            rand uvm_reg_field MAX_DROP;
            // <<UVM_REG_FIELDS>>

            `uvm_object_utils(cfs_algn_reg_irq)

            function new(string name = "");
                super.new(name, 32, UVM_NO_COVERAGE);
            endfunction

            virtual function void build();
                RX_FIFO_EMPTY = uvm_reg_field::type_id::create("RX_FIFO_EMPTY", null, get_full_name());
                RX_FIFO_FULL  = uvm_reg_field::type_id::create("RX_FIFO_FULL", null, get_full_name());
                TX_FIFO_EMPTY = uvm_reg_field::type_id::create("TX_FIFO_EMPTY", null, get_full_name());
                TX_FIFO_FULL  = uvm_reg_field::type_id::create("TX_FIFO_FULL", null, get_full_name());
                MAX_DROP      = uvm_reg_field::type_id::create("MAX_DROP", null, get_full_name());
                // <<UVM_CREATE_CALLS>>

                RX_FIFO_EMPTY.configure(
                    this,
                    .size(1),
                    .lsb_pos(0),
                    .access("W1C"),
                    .volatile(0),
                    .reset(1'b0),
                    .has_reset(1),
                    .is_rand(1),
                    .individually_accessible(0)
                );

                RX_FIFO_FULL.configure(
                    this,
                    .size(1),
                    .lsb_pos(1),
                    .access("W1C"),
                    .volatile(0),
                    .reset(1'b0),
                    .has_reset(1),
                    .is_rand(1),
                    .individually_accessible(0)
                );

                TX_FIFO_EMPTY.configure(
                    this,
                    .size(1),
                    .lsb_pos(2),
                    .access("W1C"),
                    .volatile(0),
                    .reset(1'b0),
                    .has_reset(1),
                    .is_rand(1),
                    .individually_accessible(0)
                );

                TX_FIFO_FULL.configure(
                    this,
                    .size(1),
                    .lsb_pos(3),
                    .access("W1C"),
                    .volatile(0),
                    .reset(1'b0),
                    .has_reset(1),
                    .is_rand(1),
                    .individually_accessible(0)
                );

                MAX_DROP.configure(
                    this,
                    .size(1),
                    .lsb_pos(4),
                    .access("W1C"),
                    .volatile(0),
                    .reset(1'b0),
                    .has_reset(1),
                    .is_rand(1),
                    .individually_accessible(0)
                );

                // <<UVM_CONFIGURE_BLOCKS>>

            endfunction
        endclass

        class cfs_algn_reg_block extends uvm_reg_block;

            rand cfs_algn_reg_ctrl CTRL;

            rand cfs_algn_reg_status STATUS;

            rand cfs_algn_reg_irqen IRQEN;

            rand cfs_algn_reg_irq IRQ;

            `uvm_object_utils(cfs_algn_reg_block)

            function new(string name = "");
                super.new(name, UVM_NO_COVERAGE);
            endfunction

            virtual function void build();

                default_map = create_map(
                    .name(              "apb_map"           ),
                    .base_addr(         'h0000              ),
                    .n_bytes(           4                   ),
                    .endian(            UVM_LITTLE_ENDIAN   ),
                    .byte_addressing(   1                   )
                );

                default_map.set_check_on_read(1);

                CTRL    = cfs_algn_reg_ctrl::type_id::create(   "CTRL",     null,   get_full_name());
                STATUS  = cfs_algn_reg_status::type_id::create( "STATUS",   null,   get_full_name());
                IRQEN   = cfs_algn_reg_irqen::type_id::create(  "IRQEN",    null,   get_full_name());
                IRQ     = cfs_algn_reg_irq::type_id::create(    "IRQ",      null,   get_full_name());


                CTRL.configure(
                    .blk_parent(this),
                    .regfile_parent(null),
                    .hdl_path("")
                );

                STATUS.configure(
                    .blk_parent(this),
                    .regfile_parent(null),
                    .hdl_path("")
                );

                IRQEN.configure(
                    .blk_parent(this),
                    .regfile_parent(null),
                    .hdl_path("")
                );

                IRQ.configure(
                    .blk_parent(this),
                    .regfile_parent(null),
                    .hdl_path("")
                );

                CTRL.build();
                STATUS.build();
                IRQEN.build();
                IRQ.build();

                default_map.add_reg(
                    .rg(CTRL),
                    .offset('h0000),
                    .rights("RW")
                );

                default_map.add_reg(
                    .rg(STATUS),
                    .offset('h000C),
                    .rights("RO")
                );

                default_map.add_reg(
                    .rg(IRQEN),
                    .offset('h00F0),
                    .rights("RW")
                );

                default_map.add_reg(
                    .rg(IRQ),
                    .offset('h00F4),
                    .rights("RW")
                );

            endfunction

        endclass

    endpackage

`endif
