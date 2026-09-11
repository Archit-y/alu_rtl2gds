# 8-bit ALU — RTL to GDSII (OpenROAD / sky130)

Full physical implementation of a parameterized 8-bit ALU, carried through
synthesis, place and route, and signoff on the open-source OpenROAD/OpenLane
flow targeting the SkyWater 130nm (sky130) PDK.

## Overview

Standard arithmetic/logic unit supporting ADD, SUB, AND, OR, XOR, NOT,
logical shift left/right, signed set-less-than, and pass-through, with a
registered output stage and zero/carry/overflow flag generation.

- Parameterized data width (default 8-bit)
- Single clock domain, active-low asynchronous reset
- Overflow detection via sign-bit comparison on ADD/SUB
- Combinational ALU core with a registered output stage to isolate the
  critical path from downstream logic

## Flow

| Stage | Tool |
|---|---|
| Synthesis | Yosys |
| Floorplanning / Placement / CTS / Routing | OpenROAD |
| Static timing analysis | OpenSTA |
| Design rule checking | Magic |
| Layout vs. schematic | Netgen |
| GDSII viewing | KLayout |

Flow orchestrated through OpenLane 2 on the sky130_fd_sc_hd standard cell
library.

## Results

| Metric | Value |
|---|---|
| Target clock period | 5 ns (200 MHz) |
| Worst setup slack | +0.93 ns (MET) |
| Worst hold slack | MET, no violations |
| Core utilization | 35% |
| DRC | Clean — 0 violations |
| LVS | Clean — 0 mismatches |

200MHz was chosen as an aggressive target given the design's small register
count and shallow per-cycle logic. Margin held, but tightly — the critical
path runs through the ADD/SUB carry chain into the output mux, confirmed
directly in the STA report. This is the expected bottleneck for an ALU of
this structure and the natural next place to optimize if the frequency
target is pushed further (e.g. a carry-select or carry-lookahead adder in
place of the ripple structure).

## Fanout

Signoff flagged 9 max-fanout violations against the sky130_fd_sc_hd limit of
4, concentrated on primary input buffers and clock tree buffers. No single
net dominates fanout the way a global reset or enable signal typically does
in larger designs — this is ordinary input distribution in a
combinational-heavy block, and it had no measurable effect on timing closure.

## Layout

![alu layout](docs/layout.png)

Full-chip GDSII view, sky130_fd_sc_hd standard cells.

## Repository structure

```
├── src/
│   └── alu.v                 # RTL
├── config.json                # OpenLane flow configuration
├── results/
│   ├── final/gds/              # Final GDSII
│   └── signoff/                # STA, DRC, LVS reports
├── docs/
│   └── layout.png               # Layout screenshot
└── README.md
```

## Reproducing this flow

```bash
git clone https://github.com/The-OpenROAD-Project/OpenLane.git
cd OpenLane && make && make pdk
git clone https://github.com/Archit-y/alu-rtl2gds.git designs/alu_pd
make mount
./flow.tcl -design alu_pd
```

## Tools

OpenROAD, OpenLane 2, Yosys, OpenSTA, Magic, Netgen, KLayout — sky130_fd_sc_hd PDK.
