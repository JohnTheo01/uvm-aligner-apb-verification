# Bug #005 — IRQ Not Triggered at Maximum CTRL.DROP_CNTR Value

**Date Found**: 2026-05-23  
**Date Fixed**: 2026-05-23  
**Type**: RTL

## Description
IRQ is not triggered when the drop counter reaches its maximum value.

## Root Cause
The condition checking for maximum DROP_CNTR value was missing 
from the interrupt logic in `cfs_regs.v`. All other counter 
boundary conditions triggered the IRQ correctly, but the 
maximum value case was not handled.

## How It Was Found
Detected by constrained random test `cfs_algn_test_random_rx_err`  
with random seed: 2061257708

## Fix
Added the missing interrupt condition in `cfs_regs.v` (line 169).

## Live Demo
[EDA Playground](https://www.edaplayground.com/x/fjvu)