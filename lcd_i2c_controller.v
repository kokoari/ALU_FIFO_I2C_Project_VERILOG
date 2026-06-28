// ============================================================================
// Module name: lcd_i2c_controller
// Description: I2C Bit-Banging Controller for an LCD display.
//              Formats the operands, the operation symbol, and the result.
// ============================================================================
module lcd_i2c_controller (
    input  clk,
    input  rst_n,
    input  start_display,
    input  [5:0] op,
    input  clk_en,
    
    input  [7:0] ascii_a_hundreds,
    input  [7:0] ascii_a_tens,
    input  [7:0] ascii_a_ones,
    
    input  [7:0] ascii_b_hundreds,
    input  [7:0] ascii_b_tens,
    input  [7:0] ascii_b_ones,
    
    input  [7:0] ascii_res_ten_thousands,
    input  [7:0] ascii_res_thousands,
    input  [7:0] ascii_res_hundreds,
    input  [7:0] ascii_res_tens,
    input  [7:0] ascii_res_ones,
    
    output reg done,
    output scl,
    inout  sda
);

    localparam I2C_IDLE      = 3'b000;
    localparam I2C_START     = 3'b001;
    localparam I2C_SEND_BYTE = 3'b010;
    localparam I2C_WAIT_ACK  = 3'b011;
    localparam I2C_STOP      = 3'b100;

    reg [2:0] state, next_state;
    reg [3:0] bit_idx;
    reg [7:0] data_byte;
    reg [3:0] char_idx;
    reg [7:0] ascii_op;

    reg scl_out;
    reg sda_out;

    assign scl = scl_out;
    assign sda = (sda_out == 1'b0) ? 1'b0 : 1'bz;

    always @(*) begin
        case (op)
            6'b000001: ascii_op = 8'h2B; // '+'
            6'b000010: ascii_op = 8'h2D; // '-'
            6'b000100: ascii_op = 8'h2A; // '*'
            6'b001000: ascii_op = 8'h7C; // '|'
            6'b010000: ascii_op = 8'h5E; // '^'
            6'b100000: ascii_op = 8'h26; // '&'
            default:   ascii_op = 8'h20; // Space
        endcase
    end

    always @(*) begin
        case (char_idx)
            4'd0:  data_byte = ascii_a_hundreds;
            4'd1:  data_byte = ascii_a_tens;
            4'd2:  data_byte = ascii_a_ones;
            4'd3:  data_byte = ascii_op;
            4'd4:  data_byte = ascii_b_hundreds;
            4'd5:  data_byte = ascii_b_tens;
            4'd6:  data_byte = ascii_b_ones;
            4'd7:  data_byte = 8'h3D; // '='
            4'd8:  data_byte = ascii_res_ten_thousands;
            4'd9:  data_byte = ascii_res_thousands;
            4'd10: data_byte = ascii_res_hundreds;
            4'd11: data_byte = ascii_res_tens;
            4'd12: data_byte = ascii_res_ones;
            default: data_byte = 8'h20;
        endcase
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state    <= I2C_IDLE;
            bit_idx  <= 4'd7;
            char_idx <= 4'd0;
            done     <= 1'b0;
            scl_out  <= 1'b1;
            sda_out  <= 1'b1;
        end else if (clk_en) begin
            state <= next_state;
            case (state)
                I2C_IDLE: begin
                    done    <= 1'b0;
                    scl_out <= 1'b1;
                    sda_out <= 1'b1;
                    if (start_display) char_idx <= 4'd0;
                end
                
                I2C_START: begin
                    sda_out <= 1'b0;
                    scl_out <= 1'b1;
                    bit_idx <= 4'd7;
                end
                
                I2C_SEND_BYTE: begin
                    scl_out <= ~scl_out;
                    if (scl_out == 1'b1) begin
                        sda_out <= data_byte[bit_idx];
                        if (bit_idx != 0) bit_idx <= bit_idx - 1;
                    end
                end
                
                I2C_WAIT_ACK: begin
                    scl_out <= ~scl_out;
                    if (scl_out == 1'b1) sda_out <= 1'b1; // Release SDA
                end
                
                I2C_STOP: begin
                    scl_out <= ~scl_out;
                    if (scl_out == 1'b0) begin
                        sda_out <= 1'b0;
                    end else begin
                        sda_out <= 1'b1;
                        if (char_idx < 4'd12) begin
                            char_idx <= char_idx + 1;
                        end else begin
                            done <= 1'b1;
                        end
                    end
                end
            endcase
        end
    end

    always @(*) begin
        next_state = state;
        case (state)
            I2C_IDLE:      if (start_display) next_state = I2C_START;
            I2C_START:     next_state = I2C_SEND_BYTE;
            I2C_SEND_BYTE: if (scl_out == 1'b1 && bit_idx == 0) next_state = I2C_WAIT_ACK;
            I2C_WAIT_ACK:  if (scl_out == 1'b1) next_state = I2C_STOP;
            I2C_STOP: begin
                if (scl_out == 1'b1) begin
                    if (char_idx < 4'd12) next_state = I2C_START;
                    else                  next_state = I2C_IDLE;
                end
            end
            default: next_state = I2C_IDLE;
        endcase
    end

endmodule