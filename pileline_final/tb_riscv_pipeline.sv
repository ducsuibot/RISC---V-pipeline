module tb_branch_jump;

    // =============================
    // Parameters
    // =============================
    parameter CLK_PERIOD = 10;
    parameter REG_COUNT  = 32;
    parameter IMEM_SIZE  = 256;

    // =============================
    // DUT signals
    // =============================
    reg clk;
    reg rst_n;

    // Instance DUT
    riscv_pipeline dut (
        .clk(clk),
        .rst_n(rst_n)
    );

    // =============================
    // Clock generation
    // =============================
    initial begin
        clk = 1'b1;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // =============================
    // Reset logic
    // =============================
    initial begin
        rst_n = 1'b0;
        #(CLK_PERIOD);
        rst_n = 1'b1;
    end

    // =============================
    // Load program
    // =============================
    initial begin
        $display("==== Loading branch/jump test program ====");
        $readmemh("C:/Users/Minh Duc/Downloads/pp/program.txt", dut.fetch.imem);
    end

    // =============================
    // Load golden register file
    // =============================
    reg [31:0] golden_regfile [0:REG_COUNT-1];
    initial begin
        $display("==== Loading golden output ====");
        $readmemh("C:/Users/Minh Duc/Downloads/pp/golden_output.txt", golden_regfile);
    end

    // =============================
    // Monitor PC + Branch + Jump
    // =============================
    initial begin
        $display("==============================================================");
        $display("Time\tPC\tInstr\tPCSrc_E\tPC_Target_E\tResult_W");
        $display("==============================================================");
        $monitor("%0t\t%h\t%h\t%b\t%h\t%h",
                 $time,
                 dut.fetch.PC_F,                          // Current PC
                 dut.fetch.imem[dut.fetch.PC_F[9:2]],     // Fetched instruction
                 dut.fetch.PCSrc_E,                       // Branch/jump taken
                 dut.fetch.PC_Target_E,                   // Target address
                 dut.writeback.Result_W);                 // Writeback result
    end

    // =============================
    // Finish simulation
    // =============================
    initial begin
        #(CLK_PERIOD * 100);  // Run for 100 cycles
        check_result();
        $finish;
    end

    // =============================
    // Task: Compare register file with golden output
    // =============================
    task check_result;
        integer i;
        integer pass_count;
        integer fail_count;
    begin
        pass_count = 0;
        fail_count = 0;

        $display("\n==== Checking results ====");
        // Check for undefined values (optional robustness)
        for (i = 0; i < REG_COUNT; i = i + 1) begin
            if (dut.decode.registers[i] === 32'hx || golden_regfile[i] === 32'hx) begin
                $display("Warning: Undefined value detected in x%0d (DUT: %h, Golden: %h)", 
                         i, dut.decode.registers[i], golden_regfile[i]);
            end
        end

        // Compare DUT registers with golden output
        for (i = 0; i < REG_COUNT; i = i + 1) begin
            if (dut.decode.registers[i] === golden_regfile[i]) begin
                pass_count = pass_count + 1;
            end else begin
                fail_count = fail_count + 1;
            end
        end

        // Print all 32 registers (DUT vs Golden)
        $display("\n==== DUT Registers vs Golden Output ====");
        $display("Reg\tDUT Value\tGolden Value\tMatch?");
        $display("--------------------------------------------------");
        for (i = 0; i < REG_COUNT; i = i + 1) begin
            $display("x%0d\t0x%08h\t0x%08h\t%s",
                     i,
                     dut.decode.registers[i],
                     golden_regfile[i],
                     (dut.decode.registers[i] === golden_regfile[i]) ? "OK" : "FAIL");
        end

        // Summary
        $display("\n==== Test Summary ====");
        if (fail_count == 0)
            $display("✅ ALL TESTS PASSED! (%0d / %0d)", pass_count, REG_COUNT);
        else
            $display("❌ TEST FAILED! Passed=%0d | Failed=%0d", pass_count, fail_count);
    end
    endtask

endmodule