`timescale 1ns/1ps

module riscv_pipeline (
    input clk, rst
);

    wire Stall_F, Stall_D, Flush_D, Flush_E;
    wire [1:0] ForwardA_E, ForwardB_E;
    wire PCSrc_E;
    wire [31:0] PC_Target_E;
    wire [31:0] Instr_D, PC_D, PCPlus4_D;
    wire RegWrite_E, ALUSrc_E, MemWrite_E, Branch_E, Jump_E;
    wire [1:0] ResultSrc_E;
    wire [2:0] ALUControl_E, funct3_E;
    wire [31:0] RD1_E, RD2_E, Imm_Ext_E;
    wire [4:0] RD_E, RS1_E, RS2_E, RS1_D, RS2_D;
    wire [31:0] PC_E, PCPlus4_E;
    wire RegWrite_M, MemWrite_M;
    wire [1:0] ResultSrc_M;
    wire [4:0] RD_M;
    wire [31:0] PCPlus4_M, WriteData_M, ALU_Result_M;
    wire RegWrite_W;
    wire [1:0] ResultSrc_W;
    wire [4:0] RD_W;
    wire [31:0] PCPlus4_W, ALU_Result_W, ReadData_W;
    wire [31:0] Result_W;

    fetch_cycle fetch (
        .clk(clk), .rst(rst),
        .Stall_F(Stall_F), .Stall_D(Stall_D), .Flush_D(Flush_D),
        .PCSrc_E(PCSrc_E), .PC_Target_E(PC_Target_E),
        .Instr_D(Instr_D), .PC_D(PC_D), .PCPlus4_D(PCPlus4_D)
    );

    decode_cycle decode (
        .clk(clk), .rst(rst), .RegWriteW(RegWrite_W), .RDW(RD_W), .ResultW(Result_W),
        .Flush_E(Flush_E), .Instr_D(Instr_D), .PC_D(PC_D), .PCPlus4_D(PCPlus4_D),
        .RegWrite_E(RegWrite_E), .ALUSrc_E(ALUSrc_E), .MemWrite_E(MemWrite_E), .Branch_E(Branch_E), .Jump_E(Jump_E),
        .ResultSrc_E(ResultSrc_E), .ALUControl_E(ALUControl_E), .funct3_E(funct3_E),
        .RD1_E(RD1_E), .RD2_E(RD2_E), .Imm_Ext_E(Imm_Ext_E),
        .RD_E(RD_E), .RS1_E(RS1_E), .RS2_E(RS2_E), .RS1_D(RS1_D), .RS2_D(RS2_D),
        .PC_E(PC_E), .PCPlus4_E(PCPlus4_E)
    );

    execute_cycle execute (
        .clk(clk), .rst(rst), .RegWrite_E(RegWrite_E), .ALUSrc_E(ALUSrc_E), .MemWrite_E(MemWrite_E), .Branch_E(Branch_E), .Jump_E(Jump_E),
        .ResultSrc_E(ResultSrc_E), .ALUControl_E(ALUControl_E), .funct3_E(funct3_E),
        .RD1_E(RD1_E), .RD2_E(RD2_E), .Imm_Ext_E(Imm_Ext_E), .RD_E(RD_E), .PC_E(PC_E), .PCPlus4_E(PCPlus4_E),
        .ResultW(Result_W), .ForwardA_E(ForwardA_E), .ForwardB_E(ForwardB_E),
        .PCSrc_E(PCSrc_E), .PC_Target_E(PC_Target_E), .RegWrite_M(RegWrite_M), .MemWrite_M(MemWrite_M),
        .ResultSrc_M(ResultSrc_M), .RD_M(RD_M), .PCPlus4_M(PCPlus4_M), .WriteData_M(WriteData_M), .ALU_Result_M(ALU_Result_M)
    );

    memory_cycle memory (
        .clk(clk), .rst(rst), .RegWrite_M(RegWrite_M), .MemWrite_M(MemWrite_M), .ResultSrc_M(ResultSrc_M), .RD_M(RD_M),
        .PCPlus4_M(PCPlus4_M), .WriteData_M(WriteData_M), .ALU_Result_M(ALU_Result_M),
        .RegWrite_W(RegWrite_W), .ResultSrc_W(ResultSrc_W), .RD_W(RD_W),
        .PCPlus4_W(PCPlus4_W), .ALU_Result_W(ALU_Result_W), .ReadData_W(ReadData_W)
    );

    writeback_cycle writeback (
        .ResultSrc_W(ResultSrc_W), .PCPlus4_W(PCPlus4_W), .ALU_Result_W(ALU_Result_W), .ReadData_W(ReadData_W),
        .Result_W(Result_W)
    );

    hazard_unit hazard (
        .RS1_D(RS1_D), .RS2_D(RS2_D), .RS1_E(RS1_E), .RS2_E(RS2_E), .Rd_E(RD_E), .Rd_M(RD_M), .Rd_W(RD_W),
        .RegWrite_M(RegWrite_M), .RegWrite_W(RegWrite_W), .ResultSrc_E(ResultSrc_E), .PCSrc_E(PCSrc_E),
        .ForwardA_E(ForwardA_E), .ForwardB_E(ForwardB_E), .Stall_F(Stall_F), .Stall_D(Stall_D), .Flush_D(Flush_D), .Flush_E(Flush_E)
    );

endmodule