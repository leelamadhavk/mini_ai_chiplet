`timescale 1ns/1ps

module tb_mini_ai_chiplet_soc;

    localparam DATA_WIDTH = 8;
    localparam NUM_INPUTS = 4;
    localparam ACC_WIDTH  = 20;
    localparam ADDR_WIDTH = 4;

    reg clk = 0;
    reg rst_n = 0;
    reg start = 0;

    reg [DATA_WIDTH*NUM_INPUTS-1:0] X_FLAT;
    reg [DATA_WIDTH*NUM_INPUTS-1:0] W_FLAT;
    reg [DATA_WIDTH-1:0]            BIAS;
    reg [ADDR_WIDTH-1:0]            RD_ADDR;

    wire [ACC_WIDTH-1:0] RESULT;
    wire                 RESULT_VALID;
    wire                 BUSY;

    // 100 MHz clock
    always #5 clk = ~clk;

    mini_ai_chiplet_soc #(
        .DATA_WIDTH (DATA_WIDTH),
        .NUM_INPUTS (NUM_INPUTS),
        .ACC_WIDTH  (ACC_WIDTH),
        .ADDR_WIDTH (ADDR_WIDTH)
    ) DUT (
        .clk          (clk),
        .rst_n        (rst_n),
        .start        (start),
        .X_FLAT       (X_FLAT),
        .W_FLAT       (W_FLAT),
        .BIAS         (BIAS),
        .RD_ADDR      (RD_ADDR),
        .RESULT       (RESULT),
        .RESULT_VALID (RESULT_VALID),
        .BUSY         (BUSY)
    );

    task run_inference(
        input [DATA_WIDTH-1:0] x0, x1, x2, x3,
        input [DATA_WIDTH-1:0] w0, w1, w2, w3,
        input [DATA_WIDTH-1:0] bias
    );
        begin
            X_FLAT = {x3, x2, x1, x0};
            W_FLAT = {w3, w2, w1, w0};
            BIAS   = bias;
            @(posedge clk);
            start = 1;
            @(posedge clk);
            start = 0;
            wait (RESULT_VALID == 1'b1);
            $display("Time=%0t  AI chiplet produced a result (written to memory chiplet)", $time);
            @(posedge clk);
        end
    endtask

    initial begin
        rst_n   = 0;
        RD_ADDR = 0;
        #20;
        rst_n = 1;

        // Inference 1: activations [1,2,3,4], weights [1,1,1,1], bias 0
        // expected = 1+2+3+4+0 = 10
        run_inference(8'd1, 8'd2, 8'd3, 8'd4, 8'd1, 8'd1, 8'd1, 8'd1, 8'd0);

        // Inference 2: activations [5,4,6,2], weights [3,2,4,1], bias 2
        // expected = 5*3 + 4*2 + 6*4 + 2*1 + 2 = 15+8+24+2+2 = 51
        run_inference(8'd5, 8'd4, 8'd6, 8'd2, 8'd3, 8'd2, 8'd4, 8'd1, 8'd2);

        // Inference 3: forces a negative pre-activation sum to exercise ReLU
        // activations [1,1,1,1], weights [1,1,1,1], bias = -60 (as 8'd196 two's complement)
        // expected = 4 - 60 = -56 -> ReLU clamps to 0
        run_inference(8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd196);

        #20;
        // Read back all three stored results from the memory chiplet
        RD_ADDR = 0; #10; $display("Readback addr0 = %0d", RESULT);
        RD_ADDR = 1; #10; $display("Readback addr1 = %0d", RESULT);
        RD_ADDR = 2; #10; $display("Readback addr2 = %0d", RESULT);

        $finish;
    end

endmodule
