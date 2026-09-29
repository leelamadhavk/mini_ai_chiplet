// ================================================================
// MINI AI CHIPLET SOC (v2 - advanced)
// CPU chiplet --(valid/ready handshake)--> AI chiplet
//                                            |
//                                            v (write)
//                                     MEMORY chiplet <---- rd_addr (host readback)
// ================================================================
module mini_ai_chiplet_soc #(
    parameter DATA_WIDTH = 8,
    parameter NUM_INPUTS = 4,
    parameter ACC_WIDTH  = 20,
    parameter ADDR_WIDTH = 4
)(
    input  wire                              clk,
    input  wire                              rst_n,
    input  wire                              start,

    input  wire [DATA_WIDTH*NUM_INPUTS-1:0]  X_FLAT,
    input  wire [DATA_WIDTH*NUM_INPUTS-1:0]  W_FLAT,
    input  wire [DATA_WIDTH-1:0]             BIAS,

    input  wire [ADDR_WIDTH-1:0]             RD_ADDR,
    output wire [ACC_WIDTH-1:0]              RESULT,
    output wire                              RESULT_VALID,
    output wire                              BUSY
);

    wire                    cpu_valid, cpu_last, ai_ready;
    wire [DATA_WIDTH-1:0]   cpu_x, cpu_w, cpu_b;
    wire                    ai_valid;
    wire [ACC_WIDTH-1:0]    ai_result;

    cpu_chiplet #(
        .DATA_WIDTH (DATA_WIDTH),
        .NUM_INPUTS (NUM_INPUTS)
    ) CPU (
        .clk        (clk),
        .rst_n      (rst_n),
        .start      (start),
        .X_FLAT     (X_FLAT),
        .W_FLAT     (W_FLAT),
        .BIAS       (BIAS),
        .valid_out  (cpu_valid),
        .ready_in   (ai_ready),
        .X_OUT      (cpu_x),
        .W_OUT      (cpu_w),
        .B_OUT      (cpu_b),
        .last_out   (cpu_last),
        .busy       (BUSY)
    );

    ai_chiplet #(
        .DATA_WIDTH (DATA_WIDTH),
        .ACC_WIDTH  (ACC_WIDTH)
    ) AI (
        .clk        (clk),
        .rst_n      (rst_n),
        .valid_in   (cpu_valid),
        .ready_out  (ai_ready),
        .X_IN       (cpu_x),
        .W_IN       (cpu_w),
        .B_IN       (cpu_b),
        .last_in    (cpu_last),
        .valid_out  (ai_valid),
        .Y_OUT      (ai_result)
    );

    memory_chiplet #(
        .DATA_WIDTH (ACC_WIDTH),
        .ADDR_WIDTH (ADDR_WIDTH)
    ) MEM (
        .clk        (clk),
        .rst_n      (rst_n),
        .wr_en      (ai_valid),
        .wr_data    (ai_result),
        .rd_addr    (RD_ADDR),
        .rd_data    (RESULT),
        .wr_ptr     ()
    );

    assign RESULT_VALID = ai_valid;

endmodule
