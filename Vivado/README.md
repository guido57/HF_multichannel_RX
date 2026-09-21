# Zynq-7020 1 kHz sine DDS

A small synthesizable DDS core for the Smart Zynq SP2's assumed `xc7z020clg484-2` device. It assumes a 100 MHz fabric clock and emits signed 16-bit `sine_out` and `cosine_out` samples at 1 kHz. The cosine output is phase-shifted by 90°. The 32-bit phase accumulator has a frequency resolution of about 0.023 Hz; with the defaults, its actual output is 1000.0076 Hz.

Create the Vivado project:

```sh
cd zynq7020_sine_demo
vivado -mode batch -source create_project.tcl
```

Create a block design that instantiates the DDS and exposes `clk`, `rst_n`, and
`sine_out` as external ports (with the project closed):

```sh
vivado -mode batch -source create_block_design.tcl
```

To use the Zynq processing system's internal 100 MHz PL clock (`FCLK_CLK0`) for
the DDS, close the project and run:

```sh
vivado -mode batch -source add_ps_pl_clock.tcl
```

Run behavioral simulation (from this directory, so the LUT file can be found):

```sh
source /tools/AMDDesignTools2026.1/2026.1/Vivado/settings64.sh
vivado -mode batch -source sim/run_sim.tcl
```

In the simulator waveform window, add `sine_out` (signed decimal) and `phase_out`. One sine cycle lasts 1 ms. For actual hardware, connect `sine_out` to a suitable DAC/PWM/IP path and supply the stated 100 MHz clock/reset.

Before using the command line, load the Vivado environment with the `settings64.sh` command above.
