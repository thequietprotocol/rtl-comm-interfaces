
module uart_rx #(
    parameter clk_freq = 100_000_000,
    parameter baud_rate = 19200,
    parameter no_data_bits = 8,
    parameter stop_bit_ticks = 16  // 1 bit period = 16 ticks
)(
    input logic clk, 
    input logic rst, 
    input logic rx, 
    output logic [7:0] rx_data_out,
    output logic rx_done
);

logic s_tick;
logic [31:0] count;
localparam clk_count = clk_freq / (baud_rate * 16);

// Baud Generator - Oversampling Factor 16
always_ff @(posedge clk) begin
    if(rst) begin 
        count <= '0;
        s_tick <= '0;
    end else if(count == clk_count - 1) begin
        count <= '0;
        s_tick <= 1'b1;
    end else begin
        count <= count + 1;
        s_tick <= 1'b0;
    end
end

enum logic [1:0] {idle, start, data, stop} state, next_state;
// State Register
always_ff @(posedge clk) begin
    if(rst) state <= idle;
    else state <= next_state;
end

logic [3:0] s;
logic [$clog2(no_data_bits)-1:0] n;
logic [7:0] rx_shift_reg;
// Counters and Shift Register
always_ff @(posedge clk) begin
    if(rst) begin
        s <= '0;
        n <= '0;
        rx_shift_reg <= 0;
    end else
        case(state)
            idle:  
                if(rx == 0) s <= '0;
            start: 
                if(s_tick == 1)
                    if(s == 7) begin
                        s <= '0;
                        n <= '0;
                    end else s <= s + 1;
            data: 
                if(s_tick == 1)
                    if(s == 15) begin
                        s <= '0;
                        rx_shift_reg <= {rx, rx_shift_reg[7:1]};
                        if(n != no_data_bits - 1) n <= n + 1;
                    end else s <= s + 1;
            stop: 
                if(s_tick == 1)
                    if(s != stop_bit_ticks - 1) s <= s + 1;
        endcase
end

// Next State
always_comb begin
    case(state)
        idle: 
            if(rx == 0) next_state = start; 
            else next_state = idle;
        start: 
            if((s_tick == 1) && (s == 7)) next_state = data; 
            else next_state = start; 
        data: 
            if((s_tick == 1) && (s == 15) && (n == no_data_bits - 1)) next_state = stop;
            else next_state = data; 
        stop: 
            if((s_tick == 1) && (s == stop_bit_ticks - 1)) next_state = idle;
            else next_state = stop;
        default: next_state = idle;
    endcase
end

// Output
assign rx_done = (state == stop) && (s_tick == 1) && (s == stop_bit_ticks - 1);
assign rx_data_out = rx_shift_reg;

endmodule