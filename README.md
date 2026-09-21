# HF Multi-Channel Receiver with Two Commercial Boards

![Hero: two-board HF receiver](docs/hero.png)

## Overview

**HF Hydra** is a firmware-defined, multi-channel HF receiver built around just two readily available boards: an **AD9248 ADC board** and a **SmartZynq SP2**. Flash the firmware, connect an antenna, power it up, and it becomes a networked receiver that can watch several digital-mode frequencies at the same time.

Rather than dedicating a receiver to one band or one mode, HF Hydra digitizes the incoming signal and creates independent receive slices in the FPGA. One instance can follow FT8 activity on several amateur bands, keep a WSPR channel running in the background, or be reassigned to other narrowband experiments without hardware changes.

The project goal is deliberately simple: no custom RF board, no hand-built high-speed interface, no maze of dependencies. Buy the two boards, install the image, connect the antenna, and start receiving.

## Details

### One small station, many listeners

![The two-board setup](docs/two-board-setup.png)

The AD9248 board is the acquisition end: antenna input conditioning and high-speed conversion. The SmartZynq SP2 is the processing end: it receives the sample stream, runs the digital signal processing pipeline in programmable logic, and provides the operating system and network interface.

The firmware turns a single digitized RF/IF stream into a set of configurable receive channels. Each channel has its own digital oscillator, filter, decimator, and output stream. This makes the hardware reusable: choose the frequencies in configuration instead of rewiring a receiver.

The intended first-use flow is:

1. Flash the supplied SD-card image or firmware bundle.
2. Connect the ADC board to the SmartZynq SP2 and attach the antenna.
3. Connect power and Ethernet.
4. Select a preset—such as multi-band FT8, WSPR monitoring, or a custom channel plan.

### Channels are software, not hardware

![Conceptual multi-channel waterfall](docs/multichannel-monitoring.png)

The FPGA performs the repetitive high-rate work close to the ADC: digital down-conversion, filtering, and decimation. The processor side packages lower-rate IQ or audio streams for a local decoder, a network client, or logging software.

Example channel plans:

| Preset | Example allocation |
| --- | --- |
| FT8 watcher | One receive slice per selected amateur band |
| WSPR beacon monitor | Persistent WSPR slices plus spare experimental channels |
| Mixed digital bench | FT8, WSPR, CW/skimmer, and a general-purpose IQ stream |

Actual simultaneous channel count, usable coverage, and dynamic range will be documented from measured firmware builds. Input filtering and antenna protection remain important, especially with strong nearby transmitters.

### Why these two boards?

The AD9248 provides fast dual-channel conversion, while the SmartZynq SP2 pairs FPGA fabric—ideal for many parallel DDCs—with an embedded processor that can boot, configure the receiver, and serve results over Ethernet. Together they move the difficult hardware work into a repeatable two-board assembly and leave experimentation to firmware.

## Block diagram

![HF Hydra block diagram](docs/block-diagram.png)

The antenna enters the ADC board, where it is protected, filtered, and matched before conversion. Sample data crosses to the SmartZynq SP2, whose FPGA creates independent digital channels. The SoC then exposes those channels as IQ, audio, or decoded/spot data over the network.

---

### Project status

Architecture and project presentation are in place. Next milestones: validate the ADC interface, publish a repeatable firmware image, characterize RF performance, and release channel presets and setup documentation.
