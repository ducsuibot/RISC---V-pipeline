`timescale 1ns/1ps

module fetch_cycle (
    input clk, rst, Stall_F, Stall_D, Flush_D, PCSrc_E,
    input [31:0] PC_Target_E,
    input interrupt,  // Thêm input interrupt để xử lý ngắt
    output [31:0] Instr_D, PC_D, PCPlus4_D
);

    wire [31:0] PC_F, PC_next, PC_plus4_F, Instr_F;

    // Định nghĩa địa chỉ vector cho ngắt (cố định, có thể thay đổi)
    parameter INTERRUPT_VECTOR = 32'h00000100;

    // Bộ Mux để chọn 1 trong 3 địa chỉ PC mới: ngắt ưu tiên cao nhất, sau đó là branch/jump, rồi PC+4
    assign PC_next = interrupt ? INTERRUPT_VECTOR : (PCSrc_E ? PC_Target_E : PC_plus4_F);

    // Cập nhật PC = PC next
    reg [31:0] PC_reg;
    always @(posedge clk or negedge rst) begin
        if (!rst) PC_reg <= 32'h0;
        else if (!Stall_F) PC_reg <= PC_next;
    end
    assign PC_F = PC_reg;

    // Tính PC + 4
    assign PC_plus4_F = PC_F + 32'h4;

    // Instruction memory
    reg [31:0] imem [0:255];
    assign Instr_F = imem[PC_F >> 2];

    // Lưu các giá trị ins,pc,pc+4 vào thanh ghi giữa giai đoạn fetch và decode
    reg [31:0] Instr_D_reg, PC_D_reg, PCPlus4_D_reg;
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
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

    // output của thanh ghi giữa giai đoạn fetch và decode
    assign Instr_D = Instr_D_reg;
    assign PC_D = PC_D_reg;
    assign PCPlus4_D = PCPlus4_D_reg;

endmodule