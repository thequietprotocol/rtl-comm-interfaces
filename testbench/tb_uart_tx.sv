
module tb_uart_tx;

    localparam clk_freq = 100_000_000;
    localparam baud_rate = 19200;
    localparam no_data_bits = 8;
    localparam stop_bit_ticks = 16;

    logic clk;
    logic rst;
    logic [7:0] din;
    logic tx_start;
    logic tx;
    logic tx_done;
    
    uart_tx #(
        .clk_freq(clk_freq),
        .baud_rate(baud_rate),
        .no_data_bits(no_data_bits),
        .stop_bit_ticks(stop_bit_ticks)
    ) dut (.*);

    // 100 MHz Clock (10ns period)
    always #5 clk = ~clk;

    logic [7:0] captured_byte;
    localparam int BIT_PERIOD_NS = 1_000_000_000 / baud_rate; // ~52,083 ns per bit

    initial begin
        clk = 0; rst = 1; tx_start = 0; din = 8'h00;
        #50;
        @(negedge clk) rst = 0;
        #50;

        // Test (8'ha5 -> 10100101)
        @(negedge clk); din = 8'ha5; tx_start = 1;
        @(negedge clk); tx_start = 0;

        @(negedge tx); // Start bit
        
        #(BIT_PERIOD_NS / 2); // Middle of start bit
        #(BIT_PERIOD_NS); // Middle of first bit
        
        // Sample 8 data bits
        for(int i = 0; i < 8; i++) begin
            captured_byte[i] = tx;
            #BIT_PERIOD_NS;
        end

        @(posedge tx_done);
        #50;

        if (captured_byte === 8'ha5)
            $display("\nTX STATUS: Success. Sent %0h, Received %0h\n", din, captured_byte);
        else
            $display("\nTX STATUS: Failure. Expected %0h, Received %0h\n", din, captured_byte);

        $finish;
    end

endmodule
