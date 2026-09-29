// ================================================================
// BASYS3 TOP-LEVEL WRAPPER
// Connects mini_ai_chiplet_soc to real Basys3 switches/buttons/LEDs.
//
//   SW[7:0]   -> X0 (first activation, live-adjustable)
//   SW[11:8]  -> RD_ADDR (pick which stored result to view)
//   BTNC      -> start a new inference (edge-detected -> 1-cycle pulse)
//   BTNU      -> active-high reset button (converted to active-low rst_n)
//   LED[15]   -> BUSY indicator
//   LED[14:0] -> RESULT (lower 15 bits)
//
// X1,X2,X3 and all weights/bias are fixed constants below so the
// board demo stays simple; change them to try different neurons.
// ================================================================
module basys3_top (
    input  wire        clk,
    input  wire        btnU,
    input  wire        btnC,
    input  wire [15:0] sw,
    output wire [15:0] led
);

    localparam DATA_WIDTH = 8;
    localparam NUM_INPUTS = 4;
    localparam ACC_WIDTH  = 20;
    localparam ADDR_WIDTH = 4;

    // reset: board button is active-high, our design wants active-low
    wire rst_n = ~btnU;

    // rising-edge detector on btnC so a single press gives one start pulse
    reg btnC_d1, btnC_d2;
    always @(posedge clk) begin
        btnC_d1 <= btnC;
        btnC_d2 <= btnC_d1;
    end
    wire start_pulse = btnC_d1 & ~btnC_d2;

    // live input + fixed demo constants
    wire [DATA_WIDTH-1:0] X0 = sw[7:0];
    wire [DATA_WIDTH-1:0] X1 = 8'd1;
    wire [DATA_WIDTH-1:0] X2 = 8'd1;
    wire [DATA_WIDTH-1:0] X3 = 8'd1;

    wire [DATA_WIDTH-1:0] W0 = 8'd2;
    wire [DATA_WIDTH-1:0] W1 = 8'd1;
    wire [DATA_WIDTH-1:0] W2 = 8'd1;
    wire [DATA_WIDTH-1:0] W3 = 8'd1;

    wire [DATA_WIDTH-1:0] BIAS = 8'd0;

    wire [ADDR_WIDTH-1:0] rd_addr = sw[11:8];

    wire [ACC_WIDTH-1:0] result;
    wire                 result_valid;
    wire                 busy;

    mini_ai_chiplet_soc #(
        .DATA_WIDTH (DATA_WIDTH),
        .NUM_INPUTS (NUM_INPUTS),
        .ACC_WIDTH  (ACC_WIDTH),
        .ADDR_WIDTH (ADDR_WIDTH)
    ) SOC (
        .clk          (clk),
        .rst_n        (rst_n),
        .start        (start_pulse),
        .X_FLAT       ({X3, X2, X1, X0}),
        .W_FLAT       ({W3, W2, W1, W0}),
        .BIAS         (BIAS),
        .RD_ADDR      (rd_addr),
        .RESULT       (result),
        .RESULT_VALID (result_valid),
        .BUSY         (busy)
    );

    assign led[15]   = busy;
    assign led[14:0] = result[14:0];

endmodule
