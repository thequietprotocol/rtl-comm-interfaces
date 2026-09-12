
module spi_master #(
    parameter NO_DATA_BITS = 8
)(
    input  logic clk, 
    input  logic rst, 
    input  logic start,
    input  logic [NO_DATA_BITS-1:0] din, 
    output logic [NO_DATA_BITS-1:0] dout,
    output logic ready,
    output logic spi_done,

    input  logic pol,  // Polarity
    input  logic pha,  // Phase
    input  logic [15:0] dvsr,  // Division factor to derive SPI CLK
    input  logic miso, 
    output logic mosi, 
    output logic sclk
);

typedef enum logic [1:0] {idle, sample_phase, shift_phase} state_t;

state_t state_reg, state_nxt;
logic [15:0] ticks_reg, ticks_nxt;
logic [$clog2(NO_DATA_BITS)-1:0] data_count_reg, data_count_nxt;
logic [NO_DATA_BITS-1:0] data_reg, data_nxt;
logic mosi_reg, mosi_nxt;
logic sclk_int, sclk_reg, sclk_nxt;

always_ff @(posedge clk) begin
    if(rst) begin
        state_reg      <= idle;
        ticks_reg      <= '0;
        data_count_reg <= '0;
        data_reg       <= '0;
        mosi_reg       <= '0;
        sclk_reg       <= pol;

    end else begin
        state_reg      <= state_nxt;
        ticks_reg      <= ticks_nxt;
        data_count_reg <= data_count_nxt;
        data_reg       <= data_nxt;
        mosi_reg       <= mosi_nxt;
        sclk_reg       <= sclk_nxt;
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

    case(state_reg)
        idle: 
            if(start) begin
                state_nxt      = sample_phase;
                ticks_nxt      = '0;
                data_count_nxt = '0;
                data_nxt       = din;
                mosi_nxt       = din[NO_DATA_BITS-1];
            end

        sample_phase: 
            if(ticks_reg == dvsr) begin
                state_nxt = shift_phase;
                ticks_nxt = '0;
                data_nxt  = {data_reg[NO_DATA_BITS-2:0], miso};
            end else
                ticks_nxt = ticks_reg + 1;

        shift_phase: 
            if(ticks_reg == dvsr) begin
                ticks_nxt = '0;
                if(data_count_reg == NO_DATA_BITS - 1) begin
                    state_nxt = idle;
                    spi_done  = 1'b1;
                end else begin
                    state_nxt      = sample_phase;
                    data_count_nxt = data_count_reg + 1;
                    mosi_nxt       = data_reg[NO_DATA_BITS-1];
                end
            end else
                ticks_nxt = ticks_reg + 1;

        default: begin
            state_nxt = idle;
        end
    endcase
end

assign sclk_int = ((state_nxt == shift_phase) && (!pha)) || ((state_nxt == sample_phase) && (pha));
assign sclk_nxt = (pol)? ~sclk_int : sclk_int;

// Outputs
assign mosi  = mosi_reg;
assign ready = (state_reg == idle);
assign dout  = data_reg;
assign sclk  = sclk_reg;

endmodule
