# FT8 virtual RF source sandbox

This project develops a PL-generated replacement for the board's fixed AD9248 output selection. `ad9248_clock_gen` derives complementary 64 MHz `clka` and `clkb` from the PS 128 MHz fabric clock; `ad9248_emulator` consumes those clocks and presents A/B samples alternately on one 14-bit bus.

| Signal | Direction | Meaning |
| --- | --- | --- |
| `clk_128` | input | 128 MHz PL clock for the multiplexed data path. |
| `clka`, `clkb` | internal | Complementary 64 MHz ADC clocks for channels A and B. |
| `data` | output | The board's single signed 14-bit, two's-complement ADC sample bus. |
| `otra`, `otrb` | output | Per-channel out-of-range indication. |

The board's AD9248 `MUX_SELECT` setting is fixed, so this sandbox does not expose or control it. `data` updates at 128 MS/s: A samples align to `clka` rising edges and B samples align to `clkb` rising edges. Each channel retains the documented seven-sample output pipeline. The source holds `otra` and `otrb` low because it is amplitude-limited.

The block design also connects ADC channel A to the first complex DDC. Its
initial VFO is 14.075 MHz and its external `i_out`, `q_out`, and
`output_valid` ports carry signed 24-bit complex samples at 8 ksample/s.
The GUI project's simulation top is `tb_ft8_ddc_integration`, which exercises
the complete virtual-source-to-DDC path without simulating the Zynq PS model.

Run the interface simulation after loading Vivado:

```sh
vivado -mode batch -source scripts/run_sim.tcl
```

Create the GUI project with:

```sh
vivado -mode batch -source scripts/create_project.tcl
vivado build/vivado_project/ft8_virtual_rf.xpr
```
