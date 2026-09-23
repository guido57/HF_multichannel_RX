# Vivado workspace

This directory keeps source-controlled RTL, simulations, constraints, and Tcl scripts separate from Vivado-generated projects and runs.

| Path | Purpose |
| --- | --- |
| `projects/hf_receiver/` | Main XC7Z020 receiver design. |
| `projects/ip_sine_dds/` | Self-contained DDS IP sandbox and regression simulation. |
| `projects/ip_ddc/` | 64 MS/s to 8 ksample/s complex DDC sandbox. |
| `common/` | Reusable RTL, simulation utilities, and shared constraints. |

Each project uses `rtl/`, `sim/`, `constraints/`, `scripts/`, and an ignored `build/` directory. The receiver integration belongs in `projects/hf_receiver/`; reusable blocks are developed first in their own `projects/ip_<name>/` sandboxes.

The legacy DDS experiment has been moved to [projects/ip_sine_dds](projects/ip_sine_dds/). Its project-specific build and simulation instructions are kept with the IP.
