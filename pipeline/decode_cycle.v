`timescale 1ns/1ps

module decode_cycle (
    input clk, rst, RegWriteW, Flush_E,
    input [4:0] RDW,
    input [31:0] Instr_D, PC_D, PCPlus4_D, ResultW,
    output RegWrite_E, ALUSrc_E, MemWrite_E, Branch_E, Jump_E,
    output [1:0] ResultSrc_E,
    output [2:0] ALUControl_E, funct3_E,
    output [31:0] RD1_E, RD2_E, Imm_Ext_E,
    output [4:0] RS1_E, RS2_E, RD_E, RS1_D, RS2_D,
    output [31:0] PC_E, PCPlus4_E
);

    wire RegWrite_D, ALUSrc_D, MemWrite_D, Branch_D, Jump_D;
    wire [1:0] ResultSrc_D, ImmSrc_D, ALUOp;
    wire [2:0] ALUControl_D;
    wire [31:0] RD1_D, RD2_D, Imm_Ext_D;
    wire [2:0] funct3_D;

    reg RegWrite_D_r, ALUSrc_D_r, MemWrite_D_r, Branch_D_r, Jump_D_r;
    reg [1:0] ResultSrc_D_r;
    reg [2:0] ALUControl_D_r, funct3_E_r;
    reg [31:0] RD1_D_r, RD2_D_r, Imm_Ext_D_r;
    reg [4:0] RS1_E_r, RS2_E_r, RD_E_r;
    reg [31:0] PC_E_r, PCPlus4_E_r;

    reg [10:0] control_sig;
    assign {RegWrite_D, ImmSrc_D, ALUSrc_D, MemWrite_D, ResultSrc_D, Branch_D, ALUOp, Jump_D} = control_sig;
    always @(Instr_D) begin
        case (Instr_D[6:0])
            7'b0110011: control_sig = 11'b1xx00000100; // R-type
            7'b0010011: control_sig = 11'b10010000100; // ADDI
            7'b0000011: control_sig = 11'b10010010000; // LW
            7'b0100011: control_sig = 11'b00111xx0000; // SW
            7'b1100011: control_sig = 11'b01000xx1010; // BEQ, BNE
            7'b1101111: control_sig = 11'b11110100xx1; // JAL
            default:    control_sig = 11'bxxxxxxxxxxx;
        endcase
    end

    reg [2:0] ALUControl_D_reg;
    assign ALUControl_D = ALUControl_D_reg;
    always @(ALUOp) begin
        case (ALUOp)
            2'b00: ALUControl_D_reg = 3'b000; // ADD
            2'b01: ALUControl_D_reg = 3'b001; // SUB
            2'b10: begin
                case (Instr_D[14:12])
                    3'b000: ALUControl_D_reg = (Instr_D[30] == 0) ? 3'b000 : 3'b001; // ADD/SUB
                    3'b001: ALUControl_D_reg = 3'b111; // SLL
                    3'b010: ALUControl_D_reg = 3'b101; // SLT
                    3'b011: ALUControl_D_reg = 3'b110; // SLTU
                    3'b100: ALUControl_D_reg = 3'b100; // XOR
                    3'b110: ALUControl_D_reg = 3'b011; // OR
                    3'b111: ALUControl_D_reg = 3'b010; // AND
                    default: ALUControl_D_reg = 3'bxxx;
                endcase
            end
            default: ALUControl_D_reg = 3'bxxx;
        endcase
    end

    reg [31:0] registers [0:31];
    integer i;
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            for (i = 0; i < 32; i = i + 1) registers[i] <= 32'h0;
        end else if (RegWriteW) registers[RDW] <= ResultW;
    end
    assign RD1_D = (Instr_D[19:15] != 5'b0) ? registers[Instr_D[19:15]] : 32'h0;
    assign RD2_D = (Instr_D[24:20] != 5'b0) ? registers[Instr_D[24:20]] : 32'h0;

    reg [31:0] Imm_Ext_D_reg;
    assign Imm_Ext_D = Imm_Ext_D_reg;
    always @(ImmSrc_D) begin
        case (ImmSrc_D)
            2'b00: Imm_Ext_D_reg = {{20{Instr_D[31]}}, Instr_D[31:20]}; // I
            2'b01: Imm_Ext_D_reg = {{20{Instr_D[31]}}, Instr_D[31:25], Instr_D[11:7]}; // S
            2'b10: Imm_Ext_D_reg = {{19{Instr_D[31]}}, Instr_D[31], Instr_D[7], Instr_D[30:25], Instr_D[11:8], 1'b0}; // B
            2'b11: Imm_Ext_D_reg = {{11{Instr_D[31]}}, Instr_D[31], Instr_D[19:12], Instr_D[20], Instr_D[30:21], 1'b0}; // J
            default: Imm_Ext_D_reg = 32'h0;
        endcase
    end

    assign RS1_D = Instr_D[19:15];
    assign RS2_D = Instr_D[24:20];
    assign funct3_D = Instr_D[14:12];

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            RegWrite_D_r <= 1'b0;
            ALUSrc_D_r <= 1'b0;
            MemWrite_D_r <= 1'b0;
            Branch_D_r <= 1'b0;
            Jump_D_r <= 1'b0;
            ResultSrc_D_r <= 2'b00;
            ALUControl_D_r <= 3'b000;
            funct3_E_r <= 3'b000;
            RD1_D_r <= 32'h0;
            RD2_D_r <= 32'h0;
            Imm_Ext_D_r <= 32'h0;
            RS1_E_r <= 5'h0;
            RS2_E_r <= 5'h0;
            RD_E_r <= 5'h0;
            PC_E_r <= 32'h0;
            PCPlus4_E_r <= 32'h0;
        end else if (Flush_E) begin
            RegWrite_D_r <= 1'b0;
            ALUSrc_D_r <= 1'b0;
            MemWrite_D_r <= 1'b0;
            Branch_D_r <= 1'b0;
            Jump_D_r <= 1'b0;
            ResultSrc_D_r <= 2'b00;
            ALUControl_D_r <= 3'b000;
            funct3_E_r <= 3'b000;
            RD1_D_r <= 32'h0;
            RD2_D_r <= 32'h0;
            Imm_Ext_D_r <= 32'h0;
            RS1_E_r <= 5'h0;
            RS2_E_r <= 5'h0;
            RD_E_r <= 5'h0;
            PC_E_r <= 32'h0;
            PCPlus4_E_r <= 32'h0;
        end else begin
            RegWrite_D_r <= RegWrite_D;
            ALUSrc_D_r <= ALUSrc_D;
            MemWrite_D_r <= MemWrite_D;
            Branch_D_r <= Branch_D;
            Jump_D_r <= Jump_D;
            ResultSrc_D_r <= ResultSrc_D;
            ALUControl_D_r <= ALUControl_D;
            funct3_E_r <= funct3_D;
            RD1_D_r <= RD1_D;
            RD2_D_r <= RD2_D;
            Imm_Ext_D_r <= Imm_Ext_D;
            RS1_E_r <= Instr_D[19:15];
            RS2_E_r <= Instr_D[24:20];
            RD_E_r <= Instr_D[11:7];
            PC_E_r <= PC_D;
            PCPlus4_E_r <= PCPlus4_D;
        end
    end

    assign RegWrite_E = RegWrite_D_r;
    assign ALUSrc_E = ALUSrc_D_r;
    assign MemWrite_E = MemWrite_D_r;
    assign Branch_E = Branch_D_r;
    assign Jump_E = Jump_D_r;
    assign ResultSrc_E = ResultSrc_D_r;
    assign ALUControl_E = ALUControl_D_r;
    assign funct3_E = funct3_E_r;
    assign RD1_E = RD1_D_r;
    assign RD2_E = RD2_D_r;
    assign Imm_Ext_E = Imm_Ext_D_r;
    assign RS1_E = RS1_E_r;
    assign RS2_E = RS2_E_r;
    assign RD_E = RD_E_r;
    assign PC_E = PC_E_r;
    assign PCPlus4_E = PCPlus4_E_r;

endmodule