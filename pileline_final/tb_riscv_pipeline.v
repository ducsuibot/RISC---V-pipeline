`timescale 1ns/1ps

module tb_riscv_pipeline;

    // =======================
    // Khai báo tham số
    // =======================
    parameter CLK_PERIOD = 10;    // 100 MHz
    parameter REG_COUNT  = 32;    // Số thanh ghi
    parameter IMEM_SIZE  = 256;   // Instruction memory size

    // =======================
    // Tín hiệu kết nối DUT
    // =======================
    reg clk;
    reg rst_n;

    // Instance DUT
    riscv_pipeline dut (
        .clk(clk),
        .rst_n(rst_n)
    );

    // =======================
    // Tạo clock
    // =======================
    initial begin
        clk = 1;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // =======================
    // Nạp file chương trình
    // =======================
    initial begin
        $display("==== Loading program into instruction memory ====");
        $readmemh("program.txt", dut.fetch.imem);
    end

    // =======================
    // Reset logic
    // =======================
    initial begin
        #(CLK_PERIOD);
        rst_n = 0;
        #(CLK_PERIOD);
        rst_n = 1; 
    end

    // =======================
    // Bộ nhớ chứa giá trị golden output
    // =======================
    reg [31:0] golden_regfile [0:REG_COUNT-1];

    initial begin
        $display("==== Loading golden output ====");
        $readmemh("golden_output.txt", golden_regfile);
    end

    // =======================
    // Kết thúc mô phỏng
    // =======================
    initial begin
        #(CLK_PERIOD*500); // Cho pipeline chạy 500 chu kỳ
        check_result();
        $finish;
    end

    // =======================
    // Task kiểm tra kết quả
    // =======================
    task check_result;
        integer i;
        integer pass_count;
        integer fail_count;
        begin
            pass_count = 0;
            fail_count = 0;

            $display("\n==== Checking results ====");
            for (i = 0; i < REG_COUNT; i = i + 1) begin
                if (dut.decode.registers[i] === golden_regfile[i]) begin
                    pass_count = pass_count + 1;
                end else begin
                    fail_count = fail_count + 1;
                    $display("Mismatch: x%0d => DUT=0x%08h | GOLDEN=0x%08h", 
                              i, dut.decode.registers[i], golden_regfile[i]);
                end
            end

            if (fail_count == 0)
                $display("\nALL TESTS PASSED! (%0d / %0d)", pass_count, REG_COUNT);
            else
                $display("\nTEST FAILED! Passed=%0d | Failed=%0d", pass_count, fail_count);
        end
    endtask

endmodule
