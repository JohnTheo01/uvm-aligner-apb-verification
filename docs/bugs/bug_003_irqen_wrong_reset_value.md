# Bug #003 — IRQEN register reset value = {11111} instead of {00000}

**Date Found**: 2026-05-18

## Description
Reset values for the `IRQEN register` are incorrectly enabled on reset to 1 instead of 0 (as descibed in the specifiacation sheet).


## How It Was Found
Detected by constrained random test
`cfs_algn_test_reg_access`
with random seed: 1961933807


## Fix
Changed reset values in file `cfs_regs.sv` (line 175):
From 1 turned to 0.

## Notes
In order for the bug to be visible a read access must be first in order to not override the incorrect value produced during the reset.

## Live Demo
[EDA Playground](https://www.edaplayground.com/x/H5AB)