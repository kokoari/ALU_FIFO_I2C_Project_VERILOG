// ============================================================================
// Module name: control_fsm
// Description: Finite State Machine managing the data flow from the FIFO
//              through the ALU and subsequently triggering the I2C display.
// ============================================================================
module control_fsm (
    input  clk,
    input  rst_n,
    input  btn,
    input  empty,
    input  done,
    output reg rd_en,
    output reg start_display
);

    // FSM State Encoding
    localparam IDLE    = 2'b00;
    localparam READ    = 2'b01;
    localparam EXECUTE = 2'b10;
    localparam DISPLAY = 2'b11;

    reg [1:0] state, next_state;

    // State Register (Sequential)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    // Next State and Output Logic (Combinational)
    always @(*) begin
        // Default assignments to prevent latches
        next_state    = state;
        rd_en         = 1'b0;
        start_display = 1'b0;

        case (state)
            IDLE: begin
                // Wait for user trigger to process the next transaction
                if (btn) begin
                    next_state = READ;
                end
            end
            
            READ: begin
                // If FIFO has data, read it, otherwise, return to IDLE
                if (!empty) begin
                    rd_en      = 1'b1;
                    next_state = EXECUTE;
                end else begin
                    next_state = IDLE;
                end
            end
            
            EXECUTE: begin
                // Provide a cycle for the ALU to stabilize its output
                next_state = DISPLAY;
            end
            
            DISPLAY: begin
                // Trigger the LCD update and wait for completion
                start_display = 1'b1;
                if (done) begin
                    next_state = IDLE;
                end else begin
                    next_state = DISPLAY;
                end
            end
            
            default: begin
                next_state = IDLE;
            end
        endcase
    end

endmodule