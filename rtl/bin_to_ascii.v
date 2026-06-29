// ============================================================================
// Module name: bin_to_ascii
// Description: Converts a 16-bit binary value to 5 ASCII decimal digits 
//              (Ten-Thousands, Thousands, Hundreds, Tens, Ones).
// ============================================================================
module bin_to_ascii (
    input  [15:0] bin_val,
    output reg [7:0] ascii_ten_thousands,
    output reg [7:0] ascii_thousands,
    output reg [7:0] ascii_hundreds,
    output reg [7:0] ascii_tens,
    output reg [7:0] ascii_ones
);

    integer i;
    reg [3:0] ten_thousands;
    reg [3:0] thousands;
    reg [3:0] hundreds;
    reg [3:0] tens;
    reg [3:0] ones;

    always @(*) begin
        // Initialize BCD values
        ten_thousands = 4'b0;
        thousands     = 4'b0;
        hundreds      = 4'b0;
        tens          = 4'b0;
        ones          = 4'b0;

        // Double Dabble algorithm execution
        for (i = 15; i >= 0; i = i - 1) begin
            // Add 3 if the current value is 5 or greater
            if (ten_thousands >= 5) ten_thousands = ten_thousands + 3;
            if (thousands >= 5)     thousands     = thousands + 3;
            if (hundreds >= 5)      hundreds      = hundreds + 3;
            if (tens >= 5)          tens          = tens + 3;
            if (ones >= 5)          ones          = ones + 3;

            // Shift left by 1
            ten_thousands = {ten_thousands[2:0], thousands[3]};
            thousands     = {thousands[2:0],     hundreds[3]};
            hundreds      = {hundreds[2:0],      tens[3]};
            tens          = {tens[2:0],          ones[3]};
            ones          = {ones[2:0],          bin_val[i]};
        end

        // Add 0x30 (ASCII '0') to BCD values
        ascii_ten_thousands = {4'b0011, ten_thousands};
        ascii_thousands     = {4'b0011, thousands};
        ascii_hundreds      = {4'b0011, hundreds};
        ascii_tens          = {4'b0011, tens};
        ascii_ones          = {4'b0011, ones};
    end

endmodule