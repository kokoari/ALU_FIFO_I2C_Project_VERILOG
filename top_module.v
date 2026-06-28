// ============================================================================
// Module name: top_module
// ============================================================================
module top_module #(
    parameter DATA_WIDTH = 8
)(
    input  clk_50MHz,
    input  rst_n,
    
    input  btn_save_raw,
    input  btn_send_raw,
    
    input  [DATA_WIDTH-1:0] sw_a,
    input  [DATA_WIDTH-1:0] sw_b,
    input  [5:0]            sw_op,
    
    output scl,
    inout  sda
);

    localparam ALU_RES_WIDTH  = 2 * DATA_WIDTH;
    localparam ASCII_IN_WIDTH = 16;

    wire clk_en_sig;
    wire btn_save_pulse;
    wire btn_send_pulse;
    
    wire fifo_empty, fifo_full, fifo_rd_en;
    wire start_display_sig, display_done_sig;

    wire [DATA_WIDTH-1:0]    fifo_out_a;
    wire [DATA_WIDTH-1:0]    fifo_out_b;
    wire [5:0]               fifo_out_op;
    wire [ALU_RES_WIDTH-1:0] alu_result;

    wire [(ALU_RES_WIDTH > ASCII_IN_WIDTH ? ALU_RES_WIDTH : ASCII_IN_WIDTH)-1:0] padded_alu_result;
    assign padded_alu_result = alu_result;

    // Added hundreds for A and B, and ten_thousands for Result
    wire [7:0] ascii_a_hundreds_sig, ascii_a_tens_sig, ascii_a_ones_sig;
    wire [7:0] ascii_b_hundreds_sig, ascii_b_tens_sig, ascii_b_ones_sig;
    wire [7:0] ascii_res_ten_thousands_sig, ascii_res_thousands_sig, ascii_res_hundreds_sig, ascii_res_tens_sig, ascii_res_ones_sig;

    clk_divider clk_divider_inst (.clk(clk_50MHz), .rst_n(rst_n), .clk_en(clk_en_sig));

    button_debouncer btn_save_debouncer (.clk(clk_50MHz), .rst_n(rst_n), .clk_en(clk_en_sig), .btn_send(btn_save_raw), .btn_debounced(btn_save_pulse));
    button_debouncer btn_send_debouncer (.clk(clk_50MHz), .rst_n(rst_n), .clk_en(clk_en_sig), .btn_send(btn_send_raw), .btn_debounced(btn_send_pulse));

    fifo_sync_param #(.WIDTH(DATA_WIDTH)) fifo_inst (
        .clk(clk_50MHz), .rst_n(rst_n), .data_in({sw_a, sw_b, sw_op}), .wr_en(btn_save_pulse),
        .rd_en(fifo_rd_en), .data_out({fifo_out_a, fifo_out_b, fifo_out_op}), .full(fifo_full), .empty(fifo_empty)
    );

    alu_param #(.WIDTH(DATA_WIDTH)) alu_inst (
        .a(fifo_out_a), .b(fifo_out_b), .op(fifo_out_op), .result(alu_result)
    );

    control_fsm control_fsm_inst (
        .clk(clk_50MHz), .rst_n(rst_n), .btn(btn_send_pulse), .empty(fifo_empty),
        .done(display_done_sig), .rd_en(fifo_rd_en), .start_display(start_display_sig)
    );

    bin_to_ascii bin_to_ascii_a (
        .bin_val             ({ {(ASCII_IN_WIDTH-DATA_WIDTH){1'b0}} , fifo_out_a }),
        .ascii_ten_thousands (),
        .ascii_thousands     (),
        .ascii_hundreds      (ascii_a_hundreds_sig),
        .ascii_tens          (ascii_a_tens_sig),
        .ascii_ones          (ascii_a_ones_sig)
    );

    bin_to_ascii bin_to_ascii_b (
        .bin_val             ({ {(ASCII_IN_WIDTH-DATA_WIDTH){1'b0}} , fifo_out_b }),
        .ascii_ten_thousands (),
        .ascii_thousands     (),
        .ascii_hundreds      (ascii_b_hundreds_sig),
        .ascii_tens          (ascii_b_tens_sig),
        .ascii_ones          (ascii_b_ones_sig)
    );

    bin_to_ascii bin_to_ascii_result (
        .bin_val             (padded_alu_result[ASCII_IN_WIDTH-1:0]),
        .ascii_ten_thousands (ascii_res_ten_thousands_sig),
        .ascii_thousands     (ascii_res_thousands_sig),
        .ascii_hundreds      (ascii_res_hundreds_sig),
        .ascii_tens          (ascii_res_tens_sig),
        .ascii_ones          (ascii_res_ones_sig)
    );

    lcd_i2c_controller lcd_i2c_controller_inst (
        .clk                     (clk_50MHz),
        .clk_en                  (clk_en_sig),
        .rst_n                   (rst_n),
        .start_display           (start_display_sig),
        .op                      (fifo_out_op),
        
        .ascii_a_hundreds        (ascii_a_hundreds_sig),
        .ascii_a_tens            (ascii_a_tens_sig),
        .ascii_a_ones            (ascii_a_ones_sig),
        
        .ascii_b_hundreds        (ascii_b_hundreds_sig),
        .ascii_b_tens            (ascii_b_tens_sig),
        .ascii_b_ones            (ascii_b_ones_sig),
        
        .ascii_res_ten_thousands (ascii_res_ten_thousands_sig),
        .ascii_res_thousands     (ascii_res_thousands_sig),
        .ascii_res_hundreds      (ascii_res_hundreds_sig),
        .ascii_res_tens          (ascii_res_tens_sig),
        .ascii_res_ones          (ascii_res_ones_sig),
        
        .done                    (display_done_sig),
        .scl                     (scl),
        .sda                     (sda)
    );

endmodule