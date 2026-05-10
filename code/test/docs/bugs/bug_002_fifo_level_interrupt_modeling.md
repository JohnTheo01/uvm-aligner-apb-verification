# Bug #002 — Incorrect FIFO Level Interrupt Modeling

**Date Found**: 2026-05-10  
**Date Fixed**: 2026-05-XX  
**Type**: Verification Model (not RTL)

## Description
When a FIFO level condition (rx_lvl=0, tx_lvl=0, rx_full, tx_full) 
is active and a simultaneous push/pull occurs, the model incorrectly 
produces a transient level transition that triggers an interrupt,
while the RTL does not.

## Affected Conditions
- RX empty (rx_lvl=0)
- TX empty (tx_lvl=0)  
- RX full (rx_lvl = 8)  
- TX full (tx_lvl = 8)

## Assumption
RTL behavior is considered correct. The model was updated
to match RTL behavior.

## Note
In a real project this would require clarification from the
concept engineer to determine if this is a feature or a bug.


