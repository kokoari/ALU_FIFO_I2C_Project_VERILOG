// ============================================================================
// Module name: alu_param
// Description: Parameterized Arithmetic Logic Unit (ALU)
//              Performs arithmetic and bitwise operations based on a 6-bit
//              one-hot encoded operation code (op).
// ============================================================================
module alu_param #(
    parameter WIDTH = 8
)(
    input  [WIDTH-1:0]       a,
    input  [WIDTH-1:0]       b,
    input  [5:0]             op,
    output reg [(2*WIDTH)-1:0] result
);
    
    always @(*) begin
        case (op)
            6'b000001: result = a + b; // Addition
            6'b000010: result = a - b; // Subtraction
            6'b000100: result = a * b; // Multiplication
            6'b001000: result = a | b; // Bitwise OR
            6'b010000: result = a ^ b; // Bitwise XOR
            6'b100000: result = a & b; // Bitwise AND
            default:   result = {(2*WIDTH){1'b0}}; // Default case to prevent latches
        endcase
    end
endmodule