// ============================================================================
// Module name: button_debouncer
// Description: Filters out mechanical bounce from button inputs using a 
//              synchronous clock enable mechanism on the master clock domain.
// ============================================================================
module button_debouncer (
    input  clk,
    input  rst_n,
    input  clk_en, // Synchronous clock enable pulse from clk_divider
    input  btn_send,
    output btn_debounced
);

    reg [11:0] counter; 
    reg btn_stable = 1'b0;
    reg r2 = 1'b0;
    reg r1 = 1'b0;

    // Debounce logic driven by the master clock via clock enable
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter    <= 12'b0;
            btn_stable <= 1'b0;
        end else begin
            if (clk_en) begin
                if (!btn_send) begin
                    counter    <= 12'b0;
                    btn_stable <= 1'b0;
                end else if (btn_send && counter < 12'd4000) begin
                    counter <= counter + 1'b1;
                end else if (counter >= 12'd4000) begin
                    btn_stable <= 1'b1;
                end
            end
        end
    end

    // 2-Flip-Flop Synchronizer and Edge Detector
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r1 <= 1'b0;
            r2 <= 1'b0;
        end else begin
            r1 <= btn_stable;
            r2 <= r1;
        end
    end

    assign btn_debounced = r1 && ~r2;
endmodule
