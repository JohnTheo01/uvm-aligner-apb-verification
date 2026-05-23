+uvm_set_verbosity=uvm_test_top.*,_ALL_,UVM_NONE,time,0

//+uvm_set_verbosity=uvm_test_top.*,RX_FIFO,UVM_MEDIUM,time,0

// Είναι built-in identifier, του uvm
+uvm_set_verbosity=uvm_test_top.*,REG_PREDICT,UVM_HIGH,time,0

// +uvm_set_verbosity=*md_*_agent.monitor*,ITEM_END,UVM_LOW,time,0

+uvm_set_verbosity=uvm_test_top.*,RX_FIFO,UVM_HIGH,time,0
+uvm_set_verbosity=uvm_test_top.*,TX_FIFO,UVM_HIGH,time,0
+uvm_set_verbosity=uvm_test_top.*,CNT_DROP,UVM_HIGH,time,0

