`timescale 1ns/1ps

module riscv_pipeline (
    input  wire clk,
    input  wire rst_n
);

    wire [31:0] Instr_E, Instr_M, Instr_W;

    // -----------------------------------------------------------------
    // Internal wires: IF -> ID
    // -----------------------------------------------------------------
    wire        Stall_F;
    wire        Stall_D;
    wire        Flush_D;
    wire        Flush_E;

    wire        PCSrc_E;            // from EX: jump/branch decision
    wire [31:0] ALU_Result_E;       // from EX: branch/jump target (PC_target)

    wire [31:0] Instr_D;
    wire [31:0] PC_D;
    wire [31:0] PCPlus4_D;

    // -----------------------------------------------------------------
    // Internal wires: ID -> EX
    // -----------------------------------------------------------------
    wire        RegWrite_E;
    wire        ALUSrcA_E;
    wire        ALUSrcB_E;
    wire        MemWrite_E;
    wire        MemRead_E;
    wire        Branch_E;
    wire        Jump_E;
    wire [1:0]  ResultSrc_E;
    wire [3:0]  ALUControl_E;
    wire [2:0]  funct3_E;
    wire [31:0] RD1_E;
    wire [31:0] RD2_E;
    wire [31:0] Imm_Ext_E;
    wire [4:0]  RS1_E;
    wire [4:0]  RS2_E;
    wire [4:0]  RD_E;
    wire [31:0] PC_E;
    wire [31:0] PCPlus4_E;

    // also outputs from decode for hazard detection
    wire [4:0]  RS1_D;
    wire [4:0]  RS2_D;

    // -----------------------------------------------------------------
    // Internal wires: EX -> MEM
    // -----------------------------------------------------------------
    wire        RegWrite_M;
    wire        MemWrite_M;
    wire        MemRead_M;
    wire [1:0]  ResultSrc_M;
    wire [2:0]  funct3_M;
    wire [4:0]  RD_M;
    wire [31:0] PCPlus4_M;
    wire [31:0] WriteData_M;
    wire [31:0] ALU_Result_M;

    // -----------------------------------------------------------------
    // Internal wires: MEM -> WB
    // -----------------------------------------------------------------
    wire        RegWrite_W;
    wire [1:0]  ResultSrc_W;
    wire [4:0]  RD_W;
    wire [31:0] PCPlus4_W;
    wire [31:0] ALU_Result_W;
    wire [31:0] ReadData_W;

    // -----------------------------------------------------------------
    // Internal wires: WB -> RF
    // -----------------------------------------------------------------
    wire [31:0] Result_W;

    // -----------------------------------------------------------------
    // Forwarding / Hazard signals
    // -----------------------------------------------------------------
    wire [1:0] ForwardA_E;
    wire [1:0] ForwardB_E;

    // -----------------------------------------------------------------
    // 1) FETCH stage
    // -----------------------------------------------------------------
    fetch_cycle fetch (
        .clk        (clk),
        .rst_n      (rst_n),
        .Stall_F    (Stall_F),
        .Stall_D    (Stall_D),
        .Flush_D    (Flush_D),
        .PCSrc_E    (PCSrc_E),
        .PC_Target_E(ALU_Result_E),   // use ALU_Result_E (target) from EX
        .Instr_D    (Instr_D),
        .PC_D       (PC_D),
        .PCPlus4_D  (PCPlus4_D)
    );

    // -----------------------------------------------------------------
    // 2) DECODE stage (register file, control, imm gen, ID/EX reg)
    // -----------------------------------------------------------------
    decode_cycle decode (
        .clk        (clk),
        .rst_n      (rst_n),
        .Flush_E    (Flush_E),

        // inputs from IF
        .Instr_D    (Instr_D),
        .PC_D       (PC_D),
        .PCPlus4_D  (PCPlus4_D),

        // writeback -> register file
        .RegWriteW  (RegWrite_W),
        .RDW        (RD_W),
        .ResultW    (Result_W),

        // outputs to EX
        .RD1_E      (RD1_E),
        .RD2_E      (RD2_E),
        .Imm_Ext_E  (Imm_Ext_E),

        .RegWrite_E (RegWrite_E),
        .ResultSrc_E(ResultSrc_E),
        .MemWrite_E (MemWrite_E),
        .MemRead_E  (MemRead_E),
        .Jump_E     (Jump_E),
        .Branch_E   (Branch_E),
        .ALUSrcA_E  (ALUSrcA_E),
        .ALUSrcB_E  (ALUSrcB_E),
        .ALUControl_E(ALUControl_E),
        .funct3_E   (funct3_E),

        .RD_E       (RD_E),
        .RS1_E      (RS1_E),
        .RS2_E      (RS2_E),
        .PC_E       (PC_E),
        .PCPlus4_E  (PCPlus4_E),

        // for hazard detection
        .RS1_D      (RS1_D),
        .RS2_D      (RS2_D),
        .Instr_E    (Instr_E)
    );

    // -----------------------------------------------------------------
    // 3) EXECUTE stage (ALU, branch decision, EX/MEM reg)
    // -----------------------------------------------------------------
    execute_cycle execute (
        .clk            (clk),
        .rst_n          (rst_n),

        // control + control-signal inputs from ID
        .RegWrite_E     (RegWrite_E),
        .ResultSrc_E    (ResultSrc_E),
        .MemWrite_E     (MemWrite_E),
        .MemRead_E      (MemRead_E),
        .Jump_E         (Jump_E),
        .Branch_E       (Branch_E),
        .ALUSrcA_E      (ALUSrcA_E),
        .ALUSrcB_E      (ALUSrcB_E),
        .ALUControl_E   (ALUControl_E),

        // data inputs from ID (or forwarded)
        .funct3_E       (funct3_E),
        .RD1_E          (RD1_E),
        .RD2_E          (RD2_E),
        .Imm_Ext_E      (Imm_Ext_E),
        .RS1_E          (RS1_E),
        .RS2_E          (RS2_E),
        .RD_E           (RD_E),
        .PC_E           (PC_E),
        .PCPlus4_E      (PCPlus4_E),

        // forwarding / wb input
        .ResultW        (Result_W),
        .ForwardA_E     (ForwardA_E),
        .ForwardB_E     (ForwardB_E),

        // outputs to IF/hazard and to MEM
        .PCSrc_E        (PCSrc_E),

        .RegWrite_M     (RegWrite_M),
        .MemWrite_M     (MemWrite_M),
        .MemRead_M      (MemRead_M),
        .ResultSrc_M    (ResultSrc_M),
        .funct3_M       (funct3_M),
        .RD_M           (RD_M),
        .PCPlus4_M      (PCPlus4_M),
        .WriteData_M    (WriteData_M),
        .ALU_Result_M   (ALU_Result_M),
        
        .ALU_Result_E   (ALU_Result_E),
        
        .Instr_E        (Instr_E),
        .Instr_M        (Instr_M)
    );

    // -----------------------------------------------------------------
    // 4) MEMORY stage (data memory + MEM/WB reg)
    // -----------------------------------------------------------------
    memory_cycle memory (
        .clk            (clk),
        .rst_n          (rst_n),

        .RegWrite_M     (RegWrite_M),
        .MemWrite_M     (MemWrite_M),
        .MemRead_M      (MemRead_M),
        .ResultSrc_M    (ResultSrc_M),

        .funct3_M       (funct3_M),
        .RD_M           (RD_M),
        .PCPlus4_M      (PCPlus4_M),
        .WriteData_M    (WriteData_M),
        .ALU_Result_M   (ALU_Result_M),

        .RegWrite_W     (RegWrite_W),
        .ResultSrc_W    (ResultSrc_W),
        .RD_W           (RD_W),
        .PCPlus4_W      (PCPlus4_W),
        .ALU_Result_W   (ALU_Result_W),
        .ReadData_W     (ReadData_W),
        
        .Instr_M        (Instr_M),
        .Instr_W        (Instr_W)
    );

    // -----------------------------------------------------------------
    // 5) WRITEBACK stage (WB mux)
    // -----------------------------------------------------------------
    writeback_cycle writeback (
        .RegWrite_W     (RegWrite_W),
        .ResultSrc_W    (ResultSrc_W),
        .RD_W           (RD_W),
        .PCPlus4_W      (PCPlus4_W),
        .ALU_Result_W   (ALU_Result_W),
        .ReadData_W     (ReadData_W),
        .Result_W       (Result_W)
    );

    // -----------------------------------------------------------------
    // 6) HAZARD UNIT (forwarding + stall + flush generation)
    // -----------------------------------------------------------------
    // NOTE: ensure hazard_unit's port for RD_M is declared as [4:0] in the
    // hazard_unit module. If hazard_unit currently has "input RD_M" (scalar),
    // change it to "input [4:0] RD_M".
    hazard_unit hazard (
        // outputs
        .Stall_F    (Stall_F),
        .Stall_D    (Stall_D),
        .Flush_D    (Flush_D),

        // decode -> hazard
        .RS1_D      (RS1_D),
        .RS2_D      (RS2_D),

        // flush E output
        .Flush_E    (Flush_E),

        // EX stage inputs (for forwarding)
        .RS1_E      (RS1_E),
        .RS2_E      (RS2_E),
        .RD_E       (RD_E),
        .ResultSrc_E(ResultSrc_E),
        .PCSrc_E    (PCSrc_E),

        // forwarding outputs
        .ForwardA_E (ForwardA_E),
        .ForwardB_E (ForwardB_E),

        // MEM / WB stage info for forwarding & stall
        .RD_M       (RD_M),         
        .RegWrite_M (RegWrite_M),
        .RD_W       (RD_W),
        .RegWrite_W (RegWrite_W)
    );

endmodule
