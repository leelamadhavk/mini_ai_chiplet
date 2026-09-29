// ================================================================
// AI CHIPLET
// Accepts a stream of (X,W) pairs, accumulates X*W across the
// whole stream, adds the bias on the last tap, applies ReLU,
// and produces one valid result per inference.
//   Y = ReLU( SUM(W_i * X_i) + B )
// This is a genuine (if tiny) single-neuron perceptron, not a
// single combinational multiply.
// ================================================================
module ai_chiplet #(
    parameter DATA_WIDTH = 8,
    parameter ACC_WIDTH  = 20
)(
    input  wire                       clk,
    input  wire                       rst_n,

    input  wire                       valid_in,
    output wire                       ready_out,   // always ready to accept a new tap
    input  wire [DATA_WIDTH-1:0]      X_IN,
    input  wire [DATA_WIDTH-1:0]      W_IN,
    input  wire [DATA_WIDTH-1:0]      B_IN,
    input  wire                       last_in,

    output reg                        valid_out,
    output reg  [ACC_WIDTH-1:0]       Y_OUT
);

    assign ready_out = 1'b1;

    reg  [ACC_WIDTH-1:0] acc;

    wire signed [2*DATA_WIDTH-1:0] product  = $signed(X_IN) * $signed(W_IN);
    wire signed [ACC_WIDTH-1:0]    acc_next = $signed(acc) + product;
    wire signed [ACC_WIDTH-1:0]    sum_final = acc_next + $signed(B_IN);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc       <= {ACC_WIDTH{1'b0}};
            valid_out <= 1'b0;
            Y_OUT     <= {ACC_WIDTH{1'b0}};
        end else begin
            valid_out <= 1'b0;
            if (valid_in) begin
                if (last_in) begin
                    // ReLU: negative sums clamp to zero
                    Y_OUT     <= sum_final[ACC_WIDTH-1] ? {ACC_WIDTH{1'b0}} : sum_final;
                    acc       <= {ACC_WIDTH{1'b0}};
                    valid_out <= 1'b1;
                end else begin
                    acc <= acc_next;
                end
            end
        end
    end

endmodule
