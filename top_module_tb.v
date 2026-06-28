`timescale 1ns/1ps

// ============================================================================
// Module name: tb_top_module
// Description: Automated Parameterized Testbench. Applies random vectors,
//              stresses the FIFO, and self-checks expected ALU outputs.
// ============================================================================
module tb_top_module;

    parameter DATA_WIDTH = 8;

    reg  clk_50MHz;
    reg  rst_n;
    reg  btn_save_raw;
    reg  btn_send_raw;
    reg  [DATA_WIDTH-1:0] sw_a;
    reg  [DATA_WIDTH-1:0] sw_b;
    reg  [5:0]            sw_op;
    
    reg  [15:0] expected_result;
    integer total_tests = 0;
    integer error_count = 0;
    
    wire scl;
    wire sda;

    integer i;
    integer loop_cnt;
    
    reg [DATA_WIDTH-1:0] rand_a;
    reg [DATA_WIDTH-1:0] rand_b;
    reg [5:0]            rand_op;

    // Unit Under Test (UUT) Instantiation
    top_module #(.DATA_WIDTH(DATA_WIDTH)) uut (
        .clk_50MHz    (clk_50MHz),
        .rst_n        (rst_n),
        .btn_save_raw (btn_save_raw),
        .btn_send_raw (btn_send_raw),
        .sw_a         (sw_a),
        .sw_b         (sw_b),
        .sw_op        (sw_op),
        .scl          (scl),
        .sda          (sda)
    );


    // Clock Generation
    initial begin
        clk_50MHz = 1'b0;
    end
    always begin
        #10.0 clk_50MHz = ~clk_50MHz;
    end

    // Initialization and Reset
    initial begin
        rst_n        = 1'b0;
        btn_save_raw = 1'b1;
        btn_send_raw = 1'b1;
        sw_a         = {DATA_WIDTH{1'b0}};
        sw_b         = {DATA_WIDTH{1'b0}};
        sw_op        = 6'b0;

        repeat (5) @(posedge clk_50MHz);
        rst_n = 1'b1;
        repeat (2) @(posedge clk_50MHz);
        $display("[TB INFO] Reset released. Parameterized Testbench running with WIDTH=%0d.", DATA_WIDTH);
    end

    // Task: Save input vectors at randomized time intervals
    task save_inputs_random_time(input [DATA_WIDTH-1:0] data_a, input [DATA_WIDTH-1:0] data_b, input [5:0] opcode);
        integer wait_cycles;
        begin
            sw_a  = data_a;
            sw_b  = data_b;
            sw_op = opcode;
            repeat (2) @(posedge clk_50MHz);
            
            // Force inner debouncer pulse for deterministic test execution
            force uut.btn_save_pulse = 1'b1;
            @(posedge clk_50MHz);
            release uut.btn_save_pulse;
            
            wait_cycles = $urandom_range(10, 30);
            repeat (wait_cycles) @(posedge clk_50MHz);
        end
    endtask

    // Task: Trigger FSM logic with randomized timing
    task send_to_display_random_time;
        begin
            repeat (2) @(posedge clk_50MHz);
            
            force uut.btn_send_pulse = 1'b1;
            @(posedge clk_50MHz);
            release uut.btn_send_pulse;
            
            @(posedge uut.display_done_sig);
            repeat ($urandom_range(5, 15)) @(posedge clk_50MHz);
        end
    endtask

    // Main Test Sequence
    initial begin
        @(posedge rst_n);
        repeat (5) @(posedge clk_50MHz);

        $display("\n=== STAGE 1: RUNNING INITIAL 16 VECTORS ===");
        for (i = 0; i < 6; i = i + 1) begin
            rand_a  = $urandom % (1 << DATA_WIDTH);
            rand_b  = $urandom % (1 << DATA_WIDTH);
            rand_op = (6'b000001 << i);
            save_inputs_random_time(rand_a, rand_b, rand_op);
            total_tests = total_tests + 1;
        end

        repeat (10) begin
            rand_a  = $urandom % (1 << DATA_WIDTH);
            rand_b  = $urandom % (1 << DATA_WIDTH);
            rand_op = (6'b000001 << ($urandom % 6));
            save_inputs_random_time(rand_a, rand_b, rand_op);
            total_tests = total_tests + 1;
        end

        while (uut.fifo_empty === 1'b0) begin
            send_to_display_random_time();
        end

        $display("\n=== STAGE 2: STARTING 100 FULL FILL/EMPTY LOOPS ===");
        for (loop_cnt = 1; loop_cnt <= 100; loop_cnt = loop_cnt + 1) begin
            // Fill FIFO
            repeat (16) begin
                rand_a  = $urandom % (1 << DATA_WIDTH);
                rand_b  = $urandom % (1 << DATA_WIDTH);
                rand_op = (6'b000001 << ($urandom % 6));
                
                save_inputs_random_time(rand_a, rand_b, rand_op);
                total_tests = total_tests + 1;
            end

            // Empty FIFO
            while (uut.fifo_empty === 1'b0) begin
                send_to_display_random_time();
            end
        end

        // Final Summary
        $display("\n==================================================");
        $display("  PARAMETERIZED STRESS TEST SUMMARY (WIDTH: %0d)", DATA_WIDTH);
        $display("==================================================");
        $display("  TOTAL VECTORS TESTED : %0d", total_tests);
        $display("  TOTAL MISMATCHES     : %0d", error_count);
        $display("==================================================");
        if (error_count == 0) begin
            $display("  >>>> SUCCESS: 100%% OF THE VECTORS PASSED! <<<<");
        end else begin
            $display("  >>>> FAILED: DETECTED %0d TIMING/DATA MISMATCHES. <<<", error_count);
        end
        $display("==================================================\n");

        $stop;
    end

    // Self-Checking Block
    always @(posedge uut.start_display_sig) begin
        case (uut.fifo_out_op)
            6'b000001: expected_result = uut.fifo_out_a + uut.fifo_out_b;
            6'b000010: expected_result = uut.fifo_out_a - uut.fifo_out_b;
            6'b000100: expected_result = uut.fifo_out_a * uut.fifo_out_b;
            6'b001000: expected_result = uut.fifo_out_a | uut.fifo_out_b;
            6'b010000: expected_result = uut.fifo_out_a ^ uut.fifo_out_b;
            6'b100000: expected_result = uut.fifo_out_a & uut.fifo_out_b;
            default:   expected_result = 16'b0;
        endcase

        repeat (2) @(posedge clk_50MHz);
        
        // Check output (Note: strictly checks 16 bits)
        if (uut.alu_result[15:0] !== expected_result) begin
            $display("[ERR] !! MISMATCH !! Time: %0t ns | A: %d, B: %d, OP: %b | Expected: %d, Got: %d", 
                     $time, uut.fifo_out_a, uut.fifo_out_b, uut.fifo_out_op, expected_result, uut.alu_result[15:0]);
            error_count = error_count + 1;
        end else begin
            $display("[OK]  Vector Passed! Time: %0t ns | A: %d, B: %d, OP: %b -> Result: %d", 
                     $time, uut.fifo_out_a, uut.fifo_out_b, uut.fifo_out_op, uut.alu_result[15:0]);
        end
    end

endmodule