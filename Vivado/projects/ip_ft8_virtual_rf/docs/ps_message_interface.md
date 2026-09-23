# PS-to-PL FT8 symbol interface

Use an AXI4-Lite control peripheral in the `ft8_virtual_rf_core` clock domain. The PS supplies precomputed FT8 tones, and the core snapshots them only at `START_FT8`.

## Payload widths

An FT8 source message is **77 bits**. It is encoded with a CRC and LDPC code, then mapped to **79 channel symbols**, each selecting one of eight tones. This project accepts the latter directly: **79 × 3 = 237 bits**.

## AXI4-Lite register map

| Offset | Register | Bits | Purpose |
| --- | --- | --- | --- |
| `0x00` | `CONTROL` | 0, 1 | Write-one `START_FT8`, `STOP_FT8`. |
| `0x04` | `RF_FREQ_KHZ` | 14:0 | RF frequency, 1000 to 30000 kHz. |
| `0x08`–`0x24` | `SYMBOL_WORD[0:7]` | 31:0 | Packed `ft8_symbols[236:0]`; write word 7 last. |
| `0x28` | `STATUS` | 0, 31:1 | FT8 active state and reserved status flags. |
| `0x2C` | `SOURCE` | 0 | `0` selects the physical ADC; `1` selects virtual RF. |
| `0x30` | `VFO_HZ` | 24:0 | DDC tuning frequency in hertz. |
| `0x34` | `GAIN` | 15:0 | Reserved receive-gain setting. |
| `0x38` | `VOLUME` | 15:0 | Reserved audio-volume setting. |
| `0x3C` | `AUDIO_SOURCE` | 1:0 | Reserved audio selection: I, Q, or mute. |
| `0x40` | `IDENTIFICATION` | 31:0 | Read-only `0x46543801` (register-map version 1). |

Tone `n` occupies `ft8_symbols[3*n +: 3]`, for `n = 0` through `78`; tone values range from 0 to 7. `START_FT8` copies the eight symbol registers into an active buffer and begins only when the PS issues the command on a 15-second boundary. `STOP_FT8` immediately suppresses subsequent repetitions.

The peripheral is assigned a 4 KiB region at `0x40000000` in the Zynq PS data address space. `START_FT8` and `STOP_FT8` are one-clock pulses; their `CONTROL` bits do not remain set. All other writable registers support AXI byte strobes.

This bypasses the PL encoder while using the identical scheduler, GFSK modulator, and ADC-emulator path. It is useful for comparing generated samples against WSJT-X reference tones.
