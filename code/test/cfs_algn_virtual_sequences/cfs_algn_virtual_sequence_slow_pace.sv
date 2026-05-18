`ifndef CFS_ALGN_VIRTUAL_SEQUENCE_SLOW_PACE_SV

    `define CFS_ALGN_VIRTUAL_SEQUENCE_SLOW_PACE_SV

    class cfs_algn_virtual_sequence_slow_pace 
        extends cfs_algn_virtual_sequence_base;

        `uvm_object_utils(cfs_algn_virtual_sequence_slow_pace)

        function new(string name = "");
            super.new(name);
        endfunction

        virtual task body();
            cfs_md_sequence_simple_master rx_sequence;

            int unsigned ctrl_size = p_sequencer.model.reg_block.CTRL.SIZE.get_mirrored_value();

            fork
                begin: RX_Transaction
                    int unsigned algn_data_width = p_sequencer.model.env_config.get_algn_data_width();

                    `uvm_do_on_with(rx_sequence, super.p_sequencer.md_rx_sequencer, {
                        
                        item.data.size() >= ctrl_size;

                        ((algn_data_width / 8) + item.offset)  % item.data.size() == 0;
                        (item.offset + item.data.size()) <= (algn_data_width / 8);
                    })
                end

                begin: Tx_Transaction

                    int unsigned num_tx_items;
                    int unsigned tx_item_idx = 0;

                    do begin
                        cfs_md_sequence_simple_slave tx_sequence;
                        cfs_md_item_mon item_mon;

                        p_sequencer.md_tx_sequencer.pending_items.get(item_mon);

                        num_tx_items = rx_sequence.item.data.size() / ctrl_size;

                        `uvm_do_on_with(tx_sequence, p_sequencer.md_tx_sequencer, {
                            num_tx_items == 1                                       -> item.response == CFS_MD_OKAY;
                            num_tx_items >  1 && tx_item_idx <  (num_tx_items - 1)  -> item.response == CFS_MD_OKAY;
                            num_tx_items >  1 && tx_item_idx == (num_tx_items - 1)  -> item.response == CFS_MD_ERR;
                        })

                        tx_item_idx += 1;

                    end while(tx_item_idx < num_tx_items);
                end

            join
        endtask

    endclass

`endif
