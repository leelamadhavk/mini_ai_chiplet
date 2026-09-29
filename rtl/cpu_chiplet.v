// ================================================================
// CPU CHIPLET
// Streams NUM_INPUTS (X,W) pairs + a bias to the AI chiplet, one
// pair per cycle, using a valid/ready handshake (mimics a simple
// chiplet-to-chiplet interconnect instead of one plain wire).
// ================================================================
module cpu_chiplet #(
    parameter DATA_WIDTH = 8,
    parameter NUM_INPUTS = 4
)(
    input  wire                                clk,
    input  wire                                rst_n,
    input  wire                                start,      // pulse to begin a new inference

    input  wire [DATA_WIDTH*NUM_INPUTS-1:0]    X_FLAT,     // packed activations
    input  wire [DATA_WIDTH*NUM_INPUTS-1:0]    W_FLAT,     // packed weights
    input  wire [DATA_WIDTH-1:0]               BIAS,

    output reg                                 valid_out,  // handshake: data valid
    input  wire                                ready_in,   // handshake: downstream ready
    output reg  [DATA_WIDTH-1:0]               X_OUT,
    output reg  [DATA_WIDTH-1:0]               W_OUT,
    output reg  [DATA_WIDTH-1:0]               B_OUT,
    output reg                                 last_out,   // marks final tap of this inference
    output reg                                 busy
);

    localparam IDLE   = 2'b00,
               STREAM = 2'b01,
               DONE   = 2'b10;

    reg [1:0] state;
    reg [$clog2(NUM_INPUTS)-1:0] idx;

    wire [DATA_WIDTH-1:0] x_arr [0:NUM_INPUTS-1];
    wire [DATA_WIDTH-1:0] w_arr [0:NUM_INPUTS-1];

    genvar gi;
    generate
        for (gi = 0; gi < NUM_INPUTS; gi = gi + 1) begin : UNPACK
            assign x_arr[gi] = X_FLAT[gi*DATA_WIDTH +: DATA_WIDTH];
            assign w_arr[gi] = W_FLAT[gi*DATA_WIDTH +: DATA_WIDTH];
        end
    endgenerate

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= IDLE;
            idx       <= 0;
            valid_out <= 1'b0;
            last_out  <= 1'b0;
            busy      <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    valid_out <= 1'b0;
                    last_out  <= 1'b0;
                    if (start) begin
                        idx   <= 0;
                        busy  <= 1'b1;
                        state <= STREAM;
                    end
                end

                STREAM: begin
                    if (ready_in) begin
                        X_OUT     <= x_arr[idx];
                        W_OUT     <= w_arr[idx];
                        B_OUT     <= BIAS;
                        valid_out <= 1'b1;
                        last_out  <= (idx == NUM_INPUTS-1);
                        if (idx == NUM_INPUTS-1)
                            state <= DONE;
                        else
                            idx <= idx + 1'b1;
                    end else begin
                        valid_out <= 1'b0;
                    end
                end

                DONE: begin
                    valid_out <= 1'b0;
                    last_out  <= 1'b0;
                    busy      <= 1'b0;
                    state     <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
