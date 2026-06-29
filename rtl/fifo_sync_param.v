// ============================================================================
// Module name: fifo_sync_param
// Description: Fully parameterized Synchronous FIFO buffer using $clog2 
//              for dynamic pointer width scaling based on the DEPTH parameter.
// ============================================================================
module fifo_sync_param #(
    parameter WIDTH = 8,
    parameter DEPTH = 16
)(
    input  clk,
    input  rst_n,
    input  [(2*WIDTH)+5:0] data_in,
    input  wr_en,
    input  rd_en,
    output reg [(2*WIDTH)+5:0] data_out,
    output wire full,
    output wire empty
);

    // Dynamic pointer width calculation based on DEPTH
    localparam PTR_WIDTH = $clog2(DEPTH);

    reg [PTR_WIDTH:0] wr_ptr; // Extra bit used for wrap-around full/empty detection
    reg [PTR_WIDTH:0] rd_ptr;
    
    reg [(2*WIDTH)+5:0] fifo_mem [0:DEPTH-1];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr   <= {(PTR_WIDTH+1){1'b0}};
            rd_ptr   <= {(PTR_WIDTH+1){1'b0}};
            data_out <= {(2*WIDTH+6){1'b0}};
        end else begin
            // Write operation
            if (wr_en && !full) begin
                fifo_mem[wr_ptr[PTR_WIDTH-1:0]] <= data_in;
                wr_ptr <= wr_ptr + 1'b1;
            end
            // Read operation
            if (rd_en && !empty) begin
                data_out <= fifo_mem[rd_ptr[PTR_WIDTH-1:0]];
                rd_ptr <= rd_ptr + 1'b1;
            end
        end
    end

    // Fully parameterized conditions matching any DEPTH power of 2
    assign full  = (wr_ptr[PTR_WIDTH] != rd_ptr[PTR_WIDTH]) && 
                   (wr_ptr[PTR_WIDTH-1:0] == rd_ptr[PTR_WIDTH-1:0]);
    assign empty = (wr_ptr == rd_ptr);
endmodule