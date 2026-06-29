// ============================================================================
// Module name: clk_divider
// Description: Generates a single-cycle clock enable pulse instead of a 
//              generated clock to maintain global clock network integrity.
// ============================================================================
module clk_divider (
    input  clk,
    input  rst_n,
    output reg clk_en
);

    reg [8:0] counter;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_en  <= 1'b0;
            counter <= 9'd0;
        end else begin
            // 499 matches the period of the original divider (250 high, 250 low)
            if (counter == 9'd499) begin
                clk_en  <= 1'b1; // Assert enable for exactly one master clock cycle
                counter <= 9'd0;
            end else begin
                clk_en  <= 1'b0;
                counter <= counter + 1'b1;
            end
        end
    end
endmodule