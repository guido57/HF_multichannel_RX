# DDS IP sandbox

This standalone project is the template for independently developed and tested PL IP. It targets `xc7z020clg484-2` and implements a 32-bit phase-accumulator DDS with signed 16-bit sine and cosine outputs.

After loading the Vivado environment, run:

```sh
vivado -mode batch -source scripts/create_project.tcl
vivado -mode batch -source scripts/run_sim.tcl
```

Generated Vivado and XSim projects are written to `build/`.
