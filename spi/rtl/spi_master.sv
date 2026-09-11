
module spi_master #(
    parameter SYS_CLK = 100_000_000, // 100 MHz 
    parameter SPI_CLK =   1_000_000,  // 1 MHz
    parameter NO_DATA_BITS = 8
    
)(
    input  logic clk, 
    input  logic rst, 
    input  logic start,
    input  logic [NO_DATA_BITS-1:0] din, 
    output logic [NO_DATA_BITS-1:0] dout,
    output logic ready,
    output logic spi_done,

    input logic miso, 
    output logic mosi, 
    output logic sclk,
    output logic ss_n
);

typedef enum logic [1:0] {idle, sclk_state1, sclk_state2} state_t;
localparam CLK_COUNT = SYS_CLK / SPI_CLK;

state_t state_reg, state_nxt;
logic [$clog2(CLK_COUNT / 2)-1:0] ticks_reg, ticks_nxt;
logic [$clog2(NO_DATA_BITS)-1:0] data_count_reg, data_count_nxt;
logic [NO_DATA_BITS-1:0] data_reg, data_nxt;
logic mosi_reg, mosi_nxt;
logic ss_reg, ss_nxt;
logic sclk_reg, sclk_nxt;

always_ff @(posedge clk) begin
    if(rst) begin
        state_reg      <= idle;
        ticks_reg      <= '0;
        data_count_reg <= '0;
        data_reg       <= '0;
        mosi_reg       <= '0;
        sclk_reg       <= '0;
        ss_reg         <= 1'b1;
    end else begin
        state_reg      <= state_nxt;
        ticks_reg      <= ticks_nxt;
        data_count_reg <= data_count_nxt;
        data_reg       <= data_nxt;
        mosi_reg       <= mosi_nxt;
        sclk_reg       <= sclk_nxt;
        ss_reg         <= ss_nxt;
    end
end


// Next States
always_comb begin

    state_nxt      = state_reg;
    ticks_nxt      = ticks_reg;
    data_count_nxt = data_count_reg;
    data_nxt       = data_reg;
    mosi_nxt       = mosi_reg;
    spi_done       = '0;
    sclk_nxt       = sclk_reg;
    ss_nxt         = ss_reg;

    case(state_reg)
        idle: 
            if(start) begin
                state_nxt      = sclk_state1;
                ticks_nxt      = '0;
                data_count_nxt = '0;
                data_nxt       = din;
                mosi_nxt       = din[NO_DATA_BITS-1];
                sclk_nxt       = 1'b0;
                ss_nxt         = 1'b0;
            end

        sclk_state1: 
            if(ticks_reg == (CLK_COUNT / 2) - 1) begin
                state_nxt = sclk_state2;
                sclk_nxt  = 1'b1;
                ticks_nxt = '0;
                data_nxt  = {data_reg[NO_DATA_BITS-2:0], miso};
            end else
                ticks_nxt = ticks_reg + 1;

        sclk_state2: 
            if(ticks_reg == (CLK_COUNT / 2) - 1) begin
                ticks_nxt = '0;
                if(data_count_reg == NO_DATA_BITS - 1) begin
                    state_nxt = idle;
                    spi_done  = 1'b1;
                    sclk_nxt = 1'b0;
                    ss_nxt    = 1'b1;
                end else begin
                    state_nxt      = sclk_state1;
                    data_count_nxt = data_count_reg + 1;
                    mosi_nxt       = data_reg[NO_DATA_BITS-1];
                    sclk_nxt = 1'b0;
                end
            end else
                ticks_nxt = ticks_reg + 1;

        default: begin
            state_nxt = idle;
            sclk_nxt  = 1'b0;
            ss_nxt    = 1'b1;
        end
    endcase
end

// Outputs
assign mosi  = mosi_reg;
assign ready = (state_reg == idle);
assign dout  = data_reg;
assign sclk  = sclk_reg;
assign ss_n  = ss_reg;

endmodule
