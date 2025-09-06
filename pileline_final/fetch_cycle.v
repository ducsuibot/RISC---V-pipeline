`timescale 1ns/1ps

module fetch_cycle (
    // control sgi
    input clk, rst_n,
    // hazard
    input Stall_F, Stall_D, Flush_D,
    // branch / jump
    input PCSrc_E,
    // ALUResultsE
    input [31:0] PC_Target_E,
    // forward data 
    output [31:0] Instr_D, PC_D, PCPlus4_D
);

    wire [31:0] PC_F, PC_next, PC_plus4_F, Instr_F;

    // Thanh ghi PC
    reg [31:0] PC_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            PC_reg <= 32'h0;
        else if (!Stall_F)
            PC_reg <= PC_next;
    end
    assign PC_F = PC_reg;

    // PC + 4
    assign PC_plus4_F = PC_F + 32'h4;
    
    // Chọn giá trị PC tiếp theo
    assign PC_next = PCSrc_E ? PC_Target_E : PC_plus4_F;

    // Bộ nhớ lệnh 256 x 32-bit = 1KB
    reg [31:0] imem [0:255];
    // initial begin
    //     // Load chương trình test nếu cần
    // end
    assign Instr_F = imem[PC_F >> 2];  // PC byte → index word

    // Thanh ghi pipeline F → D
    reg [31:0] Instr_D_reg, PC_D_reg, PCPlus4_D_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Instr_D_reg <= 32'h0;
            PC_D_reg <= 32'h0;
            PCPlus4_D_reg <= 32'h0;
        end else if (Flush_D) begin
            Instr_D_reg <= 32'h0;
            PC_D_reg <= 32'h0;
            PCPlus4_D_reg <= 32'h0;
        end else if (!Stall_D) begin
            Instr_D_reg <= Instr_F;
            PC_D_reg <= PC_F;
            PCPlus4_D_reg <= PC_plus4_F;
        end
    end

    // Xuất ra các giá trị pipeline stage D
    assign Instr_D = Instr_D_reg;
    assign PC_D = PC_D_reg;
    assign PCPlus4_D = PCPlus4_D_reg;

endmodule
