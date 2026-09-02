# UART
Basys 3 (Artix-7 XC7A35T) · SystemVerilog · Vivado/XSIM

## Status
- RTL: done
- Verification: done

## Spec
- Baud rate: parameterized, `baud_rate` (default 19200), derived from `clk_freq` (default 100 MHz)
- Data bits: parameterized, `no_data_bits` (default 8), LSB first
- Oversampling: 16x (`s_tick` baud generator), mid-bit sampling on RX
- Stop bit: parameterized length, `stop_bit_ticks` (default 16 ticks = 1 bit period)
- Frame format: 1 start bit, `no_data_bits` data bits, 1 stop bit (no parity)
- Reset: synchronous, active-high

## Interface
```systemverilog
module uart_rx #(
    parameter clk_freq       = 100_000_000,
    parameter baud_rate      = 19200,
    parameter no_data_bits   = 8,
    parameter stop_bit_ticks = 16
)(
    input  logic clk, rst,
    input  logic rx,
    output logic [7:0] rx_data_out,
    output logic rx_done
);
```
```systemverilog
module uart_tx #(
    parameter clk_freq       = 100_000_000,
    parameter baud_rate      = 19200,
    parameter no_data_bits   = 8,
    parameter stop_bit_ticks = 16
)(
    input  logic clk, rst,
    input  logic [7:0] din,
    input  logic tx_start,
    output logic tx,
    output logic tx_done
);
```
