
module tb_uart_rx;

    localparam clk_freq = 100_000_000;
    localparam baud_rate = 19200;
    localparam no_data_bits = 8;
    localparam stop_bit_ticks = 16;

    logic clk;
    logic rst;
    logic rx;
    logic [7:0] rx_data_out;
    logic rx_done;

    uart_rx #(
        .clk_freq(clk_freq),
        .baud_rate(baud_rate),
        .no_data_bits(no_data_bits),
        .stop_bit_ticks(stop_bit_ticks)
    ) dut (.*);

    // 100 MHz Clock (10ns period)
    always #5 clk = ~clk;

    localparam int BIT_PERIOD_NS = (1_000_000_000 / baud_rate); 
    logic [7:0] test_byte = 8'hA5; // 10100101

    initial begin
        clk = 0; rst = 1; rx = 1'b1;
        #50; @(negedge clk) rst = 0;

        #50; rx = 1'b0; // Start Bit
        #BIT_PERIOD_NS;

        for(int i = 0; i < 8; i++) begin  // Test byte bit by bit
            rx = test_byte[i];
            #BIT_PERIOD_NS;
        end

        rx = 1'b1;  // Stop Bit

        @(posedge rx_done);
        #50;

        if(rx_data_out === test_byte)
            $display("\n RX STATUS: Success. Injected %0h, Output %0h", test_byte, rx_data_out);
        else
            $display("\n RX STATUS: Failure. Injected %0h, Output %0h", test_byte, rx_data_out);

        $finish;

    end

endmodule
