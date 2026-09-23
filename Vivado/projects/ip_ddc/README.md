# 64 MS/s to 8 ksample/s complex DDC

`ddc_64m_to_8k` is the first receiver-channel DDC. It accepts one signed
14-bit ADC channel at 64 MS/s, mixes it with a 48-bit complex NCO, and emits
signed 24-bit I/Q at 8 ksample/s.

The decimation chain is:

1. Four-stage CIC, decimation by 1000: 64 MS/s to 64 ksample/s.
2. 47-tap equiripple FIR, decimation by 8: 64 ksample/s to 8 ksample/s.

The quantized FIR has approximately 0.153 dB passband ripple through 2 kHz
and 60.9 dB rejection from 6 kHz to 32 kHz. Its two sequential MAC datapaths
finish within 47 cycles of the 128 MHz PL clock.

The FFT is deliberately not part of the synthesizable DDC. Frequency checking
belongs in the simulation testbench or PS software.
