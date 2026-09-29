// ================================================================
// MEMORY CHIPLET
// A small synchronous scratchpad RAM. Every AI-chiplet result is
// written to the next free address automatically; a host (or
// testbench) can read any stored result back through RD_ADDR.
// This behaves like a real on-die SRAM bank, not a wire pass-through.
// ================================================================
module memory_chiplet #(
    parameter DATA_WIDTH = 20,
    parameter ADDR_WIDTH = 4
)(
    input  wire                     clk,
    input  wire                     rst_n,

    input  wire                     wr_en,
    input  wire [DATA_WIDTH-1:0]    wr_data,

    input  wire [ADDR_WIDTH-1:0]    rd_addr,
    output reg  [DATA_WIDTH-1:0]    rd_data,

    output reg  [ADDR_WIDTH-1:0]    wr_ptr    // exposed so a host can know how many results exist
);

    reg [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= {ADDR_WIDTH{1'b0}};
        end else if (wr_en) begin
            mem[wr_ptr] <= wr_data;
            wr_ptr      <= wr_ptr + 1'b1;
        end
    end

    always @(posedge clk) begin
        rd_data <= mem[rd_addr];
    end

endmodule
