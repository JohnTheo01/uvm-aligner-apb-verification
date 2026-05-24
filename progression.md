# uvm-aligner-apb-verification

UVM-based verification environment for the CFS Aligner DUT with APB register interface.

---

## Phase 1 — Environment Setup (Apr 2, 2026)

- Added DUT source files (`code/src/`): aligner core, edge detect, sync FIFO, RX/TX controllers
- Established the initial UVM environment skeleton: `cfs_algn_env`, `cfs_algn_pkg`, `cfs_algn_test_base`, `cfs_algn_test_pkg`
- Initial testbench top (`testbench.sv`)

## Phase 2 — APB Agent (Apr 3–23, 2026)

- Designed the APB agent structure: agent config, interface, item base/driver/monitor types
- Added APB item classes (`cfs_apb_item_base`, `cfs_apb_item_drv`)
- Implemented APB sequencer, driver, and sequence library (random, RW, simple)
- Completed the full APB agent with coverage and reset handler, reorganized under `code/test/cfs_apb_pkg/`
- Wired the APB agent into the environment; first register-access test (`cfs_algn_test_reg_access`)

## Phase 3 — MD Protocol Agent (Apr 29, 2026)

- Built the multi-data (MD) protocol agent from scratch: master/slave agent, driver, monitor, sequencer hierarchy
- Added MD item types (base, driver, monitor), coverage, and reset handler
- Implemented MD sequence library: simple master/slave, slave response (one-shot and forever)
- Integrated the MD agent into the environment alongside APB; added random test (`cfs_algn_test_random`)

## Phase 4 — UVM Extension Package (May 1, 2026)

- Introduced `uvm_ext_pkg` as a reusable base layer on top of UVM
- Added `uvm_ext_agent_config`: common agent configuration base class
- Added `uvm_ext_reset_handler`: standardized reset handling across agents
- Completed the full extension layer: `uvm_ext_monitor`, `uvm_ext_coverage`, `uvm_ext_sequencer`, `uvm_ext_driver`, `uvm_ext_agent` — all parameterized base classes

## Phase 5 — Agent Consolidation (May 1, 2026)

- Consolidated the APB agent into a single packed file (`packed_cfs_apb_pkg.sv`) integrating `uvm_ext_pkg`
- Consolidated the MD agent into a single packed file (`packed_cfs_md_pkg.sv`) integrating `uvm_ext_pkg`
- Archived the original unpacked component files under `code/test/archive/` for reference

## Phase 6 — UVM Register Model Integration (May 3, 2026)

- Renamed packed agent packages back to individual files by removing the "packed" prefix
- Built the supporting infrastructure for register access: env config, register predictor, APB adapter, and register configuration sequence
- Wired the register model into the environment alongside reset handling support
- Fixed several bugs in the register definitions (CTRL constraints, IRQ access type, IRQEN field name)
- **Bug #001**: Discovered illegal offset/size RTL bug (offset + size > bus width not rejected); fixed in both RTL and predictor; added CTRL register constraint

## Phase 7 — Functional Model (May 4–5, 2026)

- Added CLR callback to reset `CNT_DROP` field via the register model; exercised in register access test
- Refactored `cfs_algn_reg_pkg` into a single file and inlined APB adapter for EDA Playground compatibility
- Added analysis ports to model and connected MD monitor outputs in environment
- Added illegal access detection logic to model RX handler
- Built RX FIFO model with level tracking, full interrupt support, and buffer build logic
- Added clock interface for model use; wired through testbench, env, and env_config

## Phase 8 — Align Logic + TX Controller (May 6, 2026)

- Added align logic to model: TX FIFO, split function, and non-blocking align task
- Added TX controller: tx_complete event, TX FIFO pop, and TX empty interrupt logic
- Updated random test CTRL values and data sizes to exercise align logic

## Phase 9 — Scoreboard (May 8–10, 2026)

- Added scoreboard infrastructure and wired it to model and agents in environment
- Implemented RX response checking with watchdog timer and TX item checking
- Added IRQ checking infrastructure across scoreboard, env_config, interface, and testbench
- **Bug #002**: Discovered and fixed false IRQ on simultaneous FIFO push/pull; deferred level interrupt prediction to avoid race condition

## Phase 10 — IRQ Refinement + JSON Recording (May 11–17, 2026)

- Consolidated IRQ prediction through `exp_irq` flag and negedge-clocked send task
- Added FIFO push/pop sync signals and RTL synchronization tasks to model
- Added JSON transaction recording infrastructure to `uvm_ext_pkg`; wired into APB and MD agents
- Switched random test to use virtual sequencer
- First waveform results documented for `cfs_algn_test_random`

## Phase 11 — Virtual Sequences + Coverage + Bug Fixes (May 17–23, 2026)

- Added virtual sequencer, virtual sequences (`slow_pace`, `reg_access_random`, `reg_access_unmapped`), coverage, and `cfs_algn_split_info` type
- Reorganized all virtual sequences into `cfs_algn_virtual_sequences/` folder
- Added `reg_config`, `reg_status`, and `rx` virtual sequences; refactored random test to use them
- **Bug #003**: Discovered and fixed IRQEN register reset values initialized to 1 instead of 0 (RTL)
- Fixed `rand_mode` for W1C IRQ register fields disabled by UVM after `configure()`
- **Bug #004**: Discovered and fixed register reconfiguration while model buffers were not empty; added `is_empty()` to model and guarded `WRITE_TO_REGISTERS` block
- Synchronized model with EDA Playground version: added `port_out_split_info` analysis port, renamed `uvm_info` tags, refined verbosity levels
- Added `cfs_algn_test_random_rx_err` test: forces illegal RX offset/size combinations via factory override of `rx` virtual sequence
- **Bug #005**: Discovered and fixed missing IRQ condition for max drop counter in RTL (`edge_max_drop & irqen_max_drop` term absent from IRQ assignment)
