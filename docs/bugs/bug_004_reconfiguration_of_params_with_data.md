# Bug #004 — Reconfiguration of Control Registers with Data Remaining in Aligner Buffer

**Date Found**: 2026-05-23
**Date Fixed**: 2026-05-23
**Type**: Verification Test (not RTL)

## Description
When the test reconfigures `CTRL.SIZE` and `CTRL.OFFSET` in a second iteration,
residual data may still remain in the aligner's intermediate buffer from the
previous iteration. Because the aligner waits for enough bytes to complete
one aligned word before outputting, those leftover bytes are flushed with the
new configuration's traffic, producing an unexpected output that triggers a
scoreboard error.

## Example
- `CTRL.SIZE = 4`
- First iteration sends transactions whose bytes total 3 inside the aligner buffer; no further data arrives to complete the word.
- The aligner holds those 3 bytes, waiting for 1 more.
- The test enters its second iteration and writes a new `CTRL.SIZE`/`CTRL.OFFSET`.
- The first new byte pushed to the RX FIFO completes the 4-byte word using the 3 stale bytes, and the aligner outputs it — producing data the scoreboard does not expect.

## How It Was Found
Detected by constrained random test `cfs_algn_test_random` during the
second iteration of its `repeat(2)` reconfiguration loop.

Fix commit tagged as `fix/bug_004`.

## Fix
Added `is_empty()` to `cfs_algn_model` (`cfs_algn_model.sv` line 80):
returns `1` only when `rx_fifo`, `tx_fifo`, and the intermediate `buffer`
are all empty.

In `cfs_algn_test_random.sv` (line 35), the `WRITE_TO_REGISTERS` block is
now guarded with `if (env.env_config.model.is_empty() == 1)`, so a new
`CTRL` configuration is only written when no data remains in the aligner.
Traffic driving, the wait window, and the status register read still execute
on every iteration regardless.

## Notes
RTL behavior is considered correct — the aligner is not required to flush
its buffer on a register write. The verification test was driving incorrect
stimulus by reconfiguring while data was still in-flight.
