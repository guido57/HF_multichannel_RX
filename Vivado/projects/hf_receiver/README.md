# HF receiver integration project

This is the main SmartZynq SP2 / XC7Z020 programmable-logic project. It will integrate verified IP for ADC capture, the DDC, FT8 virtual RF generation, PS streaming/control, and I²S audio.

Keep reusable blocks and unit-level simulations in `../ip_<name>/`; place only top-level integration RTL, board constraints, and integration simulation here. Generated files belong under `build/`.
