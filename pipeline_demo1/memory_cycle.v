`timescale 1ns/1ps

module memory_cycle (
    input clk, rst, RegWrite_M, MemWrite_M,
    input [1:0] ResultSrc_M,
    input [4:0] RD_M,
    input [31:0] PCPlus4_M, WriteData_M, ALU_Result_M,
    output RegWrite_W,
    output [1:0] ResultSrc_W,
    output [4:0] RD_W,
    output [31:0] PCPlus4_W, ALU_Result_W, ReadData_W
);

    reg [31:0] dmem [0:255];
    wire [31:0] ReadData_M;
    always @(posedge clk) begin
        if (MemWrite_M) dmem[ALU_Result_M >> 2] <= WriteData_M;
    end
    assign ReadData_M = dmem[ALU_Result_M >> 2];

    reg RegWrite_W_r;
    reg [1:0] ResultSrc_W_r;
    reg [4:0] RD_W_r;
    reg [31:0] PCPlus4_W_r, ALU_Result_W_r, ReadData_W_r;
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            RegWrite_W_r <= 1'b0;
            ResultSrc_W_r <= 2'b00;
            RD_W_r <= 5'h0;
            PCPlus4_W_r <= 32'h0;
            ALU_Result_W_r <= 32'h0;
            ReadData_W_r <= 32'h0;
        end else begin
            RegWrite_W_r <= RegWrite_M;
            ResultSrc_W_r <= ResultSrc_M;
            RD_W_r <= RD_M;
            PCPlus4_W_r <= PCPlus4_M;
            ALU_Result_W_r <= ALU_Result_M;
            ReadData_W_r <= ReadData_M;
        end
    end

    assign RegWrite_W = RegWrite_W_r;
    assign ResultSrc_W = ResultSrc_W_r;
    assign RD_W = RD_W_r;
    assign PCPlus4_W = PCPlus4_W_r;
    assign ALU_Result_W = ALU_Result_W_r;
    assign ReadData_W = ReadData_W_r;

endmodule