# SPI
Basys 3 (Artix-7 XC7A35T) · SystemVerilog · Vivado/XSIM

## Status
- Master RTL: done
- Master verification: in progress
- Slave RTL: not yet
- Slave verification: not yet

## Spec
- SCLK frequency: runtime configurable via `dvsr` input: `dvsr = clk_freq / (2 × f_spi) − 1`

- Data bits: parameterized, `NO_DATA_BITS` (default 8), MSB first
- Modes: all four supported at runtime via `pol` (CPOL) and `pha` (CPHA) inputs
- Slave select: not in module, driven externally (allows multi-byte transactions under one select)
- Full duplex: one bit out on MOSI and one bit in on MISO per SCLK period
- Reset: synchronous, active-high; SCLK resets to `pol`

## Design notes
- Three states: `idle`, `sample_phase`, `shift_phase` - the two phases are halves of a bit period
- MISO sampled at `sample_phase → shift_phase`; MOSI advanced at `shift_phase → sample_phase`, in all four modes
- Single 8-bit shift register shared between TX and RX, plus a 1-bit `mosi_reg` holding the outgoing bit until the change edge. 
- SCLK derived combinationally from `state_nxt` then registered, so it is glitch-free
- `dout` is valid when `spi_done` pulses (last bit arrives half a period earlier)
- `pol`, `pha`, and `dvsr` must only change while `ready` is high

## Interface
```systemverilog
module spi_master #(
    parameter NO_DATA_BITS = 8
)(
    input  logic clk, rst,
    input  logic start,
    input  logic [NO_DATA_BITS-1:0] din,
    output logic [NO_DATA_BITS-1:0] dout,
    output logic ready,
    output logic spi_done,

    input  logic pol,           // CPOL
    input  logic pha,           // CPHA
    input  logic [15:0] dvsr,   // clk_freq / (2 * f_spi) - 1
    input  logic miso,
    output logic mosi,
    output logic sclk
);
```

## Mode reference
| Mode | pol | pha | SCLK idle | Sample edge | Shift edge |
|------|-----|-----|-----------|-------------|-------------|
| 0    | 0   | 0   | low       | rising      | falling     |
| 1    | 0   | 1   | low       | falling     | rising      |
| 2    | 1   | 0   | high      | falling     | rising      |
| 3    | 1   | 1   | high      | rising      | falling     |

`sclk = pol ^ pha ^ (state == shift_phase)`, with idle at `pol`.