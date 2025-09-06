`timescale 1ns/1ps

module decode_cycle (
    // ================== CLOCK & RESET ==================
    input clk,              // Clock chính
    input rst_n,              // Reset đồng bộ
    input Flush_E,          // Flush stage EX nếu cần pipeline stall
    
    // ================== ĐẦU VÀO TỪ STAGE IF ==================
    input [31:0] Instr_D,   // Lệnh RISC-V hiện tại tại stage Decode
    input [31:0] PC_D,      // Program Counter hiện tại
    input [31:0] PCPlus4_D, // PC + 4, dùng cho JAL/JALR

    // ================== REGISTER FILE ==================
    input RegWriteW,        // Tín hiệu cho phép ghi từ stage WB
    input [4:0] RDW,        // Địa chỉ thanh ghi đích từ WB stage
    input [31:0] ResultW,   // Dữ liệu ghi về từ WB stage
    output [31:0] RD1_E,      // Toán hạng 1 từ Register File
    output [31:0] RD2_E,      // Toán hạng 2 từ Register File hoặc Data Memory
    
    // ================== IMM EXTEND ==================
    output [31:0] Imm_Ext_E,  // Immediate mở rộng từ lệnh

    // ================== CONTROL UNIT ==================
    output RegWrite_E,      // Cho phép ghi thanh ghi ở EX/WB
    output [1:0] ResultSrc_E, // Chọn dữ liệu ghi về thanh ghi
    output MemWrite_E,      // Ghi dữ liệu xuống Data Memory
    output MemRead_E,      // Đọc dữ liệu xuống Data Memory
    output Jump_E,          // Lệnh nhảy
    output Branch_E,        // Lệnh nhánh
    output ALUSrcA_E,       // Chọn toán hạng ALU: 0=RD1, 1=PC 
    output ALUSrcB_E,       // Chọn toán hạng ALU: 0=RD2, 1=Imm_Ext
    output [3:0] ALUControl_E, // Mã điều khiển ALU
    // ImmSrc 

    // ================== BRANCH UNIT (STAGE EX) ==================
    output [2:0] funct3_E,     // Lưu funct3 để dùng cho branch/load/store

    // ================== DATA FORWARD (EX) ==================
    output [4:0] RS1_E,       // Địa chỉ thanh ghi nguồn 1 sang EX
    output [4:0] RS2_E,       // Địa chỉ thanh ghi nguồn 2 sang EX
    output [4:0] RD_E,        // Địa chỉ thanh ghi đích sang EX
    output [31:0] PC_E,       // PC sang EX
    output [31:0] PCPlus4_E,   // PC+4 sang EX
    // ================== HAZARD CONTROL ==================
    output [4:0] RS1_D,       // Địa chỉ thanh ghi nguồn 1 ở stage Decode
    output [4:0] RS2_D,        // Địa chỉ thanh ghi nguồn 2 ở stage Decode
    // Debug 
    output [31:0] Instr_E
);

    // =================================================================
    // 1. CONTROL UNIT — Giải mã opcode thành tín hiệu điều khiển
    // =================================================================
    wire RegWrite_D, ALUSrcA_D, ALUSrcB_D,MemWrite_D,MemRead_D, Branch_D, Jump_D;
    wire [1:0] ResultSrc_D, ALUOp;
    wire [2:0] ImmSrc_D;

    reg [13:0] control_sig;
    assign {RegWrite_D, ImmSrc_D, ALUSrcA_D, ALUSrcB_D, MemRead_D, MemWrite_D, ResultSrc_D,
            Branch_D, ALUOp, Jump_D} = control_sig;

    always @(*) begin
        case (Instr_D[6:0])
            7'b0110011: control_sig = 14'b10000000000100; // R-type
            7'b0010011: control_sig = 14'b10000100000100; // I-type (ADDI,…)
            7'b0000011: control_sig = 14'b10000110010000; // LOAD (LW,…)
            7'b0100011: control_sig = 14'b00010101000000; // STORE (SW,…)
            7'b1100011: control_sig = 14'b00101100001010; // BRANCH (BEQ,BNE,…)
            7'b1101111: control_sig = 14'b10111100100011; // JAL
            7'b1100111: control_sig = 14'b10000100100011; // JALR
            7'b0110111: control_sig = 14'b11000100000110; // LUI
            7'b0010111: control_sig = 14'b11001100000000; // AUIPC
            default:    control_sig = 14'b00000000000000;
        endcase
    end

    // =================================================================
    // 2. ALU CONTROL — Xác định phép toán ALU
    // =================================================================
    reg [3:0] ALUControl_D;
    always @(*) begin
        case (ALUOp)
            2'b00: ALUControl_D = 4'b0000; // ADD cho load/store/auipc
            2'b01: ALUControl_D = 4'b1011; // Cong %4 =0 cho branch/jump
            2'b10: begin
                case (Instr_D[14:12]) // funct3
                    3'b000: begin
                    // Dùng cho các lệnh kiểu ADD, ADDI, SUB
                if (Instr_D[6:0] == 7'b0110011) begin
                    // R-type: ADD hoặc SUB
                     ALUControl_D = (Instr_D[30] == 1'b0) ? 4'b0000 : 4'b0001; 
                end else begin
                // I-type: ADDI
                     ALUControl_D = 4'b0000; 
                    end
                 end
                    3'b001: ALUControl_D = 4'b0111; // SLL
                    3'b010: ALUControl_D = 4'b0101; // SLT
                    3'b011: ALUControl_D = 4'b0110; // SLTU
                    3'b100: ALUControl_D = 4'b0100; // XOR
                    3'b101: ALUControl_D = (Instr_D[30]==0) ? 4'b1000 : 4'b1001; // SRL or SRA
                    3'b110: ALUControl_D = 4'b0011; // OR
                    3'b111: ALUControl_D = 4'b0010; // AND
                    default: ALUControl_D = 4'bxxx;
                endcase
            end
            2'b11 : ALUControl_D = 4'b1010; // LUI
            default: ALUControl_D = 4'bxxx;
        endcase
    end

    // =================================================================
    // 3. REGISTER FILE — Lưu trữ và đọc giá trị các thanh ghi
    // =================================================================
    wire [31:0] RD1_D, RD2_D;
    reg [31:0] registers [0:31];
    integer i;
    always @(negedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 32; i = i + 1)
                registers[i] <= 32'h0;       // Reset tất cả về 0
        end
        else if (RegWriteW && (RDW != 0))
            registers[RDW] <= ResultW;       // Ghi dữ liệu từ WB stage
    end

    // Đọc giá trị 2 thanh ghi nguồn
    assign RD1_D = (Instr_D[19:15] != 5'd0) ? registers[Instr_D[19:15]] : 32'h0;
    assign RD2_D = (Instr_D[24:20] != 5'd0) ? registers[Instr_D[24:20]] : 32'h0;

    // =================================================================
    // 4. IMMEDIATE GENERATOR — Giải mã Imm theo kiểu lệnh
    // =================================================================
    reg [31:0] Imm_Ext_D;

    always @(*) begin
        case (ImmSrc_D)
            3'b000: Imm_Ext_D = {{20{Instr_D[31]}}, Instr_D[31:20]};                                                 // I-type
            3'b001: Imm_Ext_D = {{20{Instr_D[31]}}, Instr_D[31:25], Instr_D[11:7]};                                  // S-type
            3'b010: Imm_Ext_D = {{19{Instr_D[31]}}, Instr_D[31], Instr_D[7], Instr_D[30:25], Instr_D[11:8], 1'b0};   // B-type
            3'b011: Imm_Ext_D = {{12{Instr_D[31]}}, Instr_D[19:12], Instr_D[20], Instr_D[30:21], 1'b0};              // J-type
            3'b100: Imm_Ext_D = {Instr_D[31:12], 12'b0};                                                             // U-type
            default: Imm_Ext_D = 32'bx;
        endcase
    end

    // Địa chỉ thanh ghi nguồn trong lệnh
    assign RS1_D = Instr_D[19:15];
    assign RS2_D = Instr_D[24:20];
    wire [2:0] funct3_D = Instr_D[14:12];

    // =================================================================
    // 5. PIPELINE REGISTER ID -> EX — Lưu dữ liệu qua stage EX
    // =================================================================
    
    reg RegWrite_D_r, ALUSrcA_D_r, ALUSrcB_D_r, MemWrite_D_r, MemRead_D_r, Branch_D_r, Jump_D_r;
    reg [1:0] ResultSrc_D_r;
    reg [3:0] ALUControl_D_r;
    reg [2:0] funct3_E_r;
    reg [31:0] RD1_D_r, RD2_D_r, Imm_Ext_D_r;
    reg [4:0] RS1_E_r, RS2_E_r, RD_E_r;
    reg [31:0] PC_E_r, PCPlus4_E_r;
    reg [31:0] Instr_E_r;

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n || Flush_E) begin
            // Reset hoặc flush EX stage
            RegWrite_D_r <= 1'b0; 
            ALUSrcA_D_r  <= 1'b0;
            ALUSrcB_D_r  <= 1'b0;
            MemWrite_D_r <= 1'b0;
            MemRead_D_r  <= 1'b0;
            Branch_D_r   <= 1'b0; 
            Jump_D_r     <= 1'b0; 
            ResultSrc_D_r <= 2'b00;
            ALUControl_D_r <= 4'b000; 
            funct3_E_r <= 3'b000;
            RD1_D_r <= 32'h0; 
            RD2_D_r <= 32'h0; 
            Imm_Ext_D_r <= 32'h0;
            RS1_E_r <= 5'h0; 
            RS2_E_r <= 5'h0; 
            RD_E_r <= 5'h0;
            PC_E_r <= 32'h0; 
            PCPlus4_E_r <= 32'h0;
            //Debug
            Instr_E_r   <= 32'h0;
        end else begin
            // Truyền dữ liệu từ ID sang EX stage
            RegWrite_D_r <= RegWrite_D; 
            ALUSrcA_D_r  <= ALUSrcA_D;
            ALUSrcB_D_r  <= ALUSrcB_D;
            MemWrite_D_r <= MemWrite_D;
            MemRead_D_r  <= MemRead_D;
            Branch_D_r   <= Branch_D; 
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
            //Debug
            Instr_E_r <= Instr_D;
        end
    end

    // =================================================================
    // 6. OUTPUT SANG EX STAGE
    // =================================================================
    assign RegWrite_E  = RegWrite_D_r;
    assign ALUSrcA_E   = ALUSrcA_D_r;
    assign ALUSrcB_E   = ALUSrcB_D_r;
    assign MemWrite_E  = MemWrite_D_r;
    assign MemRead_E   = MemRead_D_r;
    assign Branch_E    = Branch_D_r;
    assign Jump_E      = Jump_D_r;
    assign ResultSrc_E = ResultSrc_D_r;
    assign ALUControl_E= ALUControl_D_r;
    assign funct3_E    = funct3_E_r;
    assign RD1_E       = RD1_D_r;
    assign RD2_E       = RD2_D_r;
    assign Imm_Ext_E   = Imm_Ext_D_r;
    assign RS1_E       = RS1_E_r;
    assign RS2_E       = RS2_E_r;
    assign RD_E        = RD_E_r;
    assign PC_E        = PC_E_r;
    assign PCPlus4_E   = PCPlus4_E_r;
    //Debug
    assign Instr_E     = Instr_E_r;

endmodule
