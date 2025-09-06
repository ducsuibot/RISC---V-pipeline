`timescale 1ns/1ps

module execute_cycle (
    // ===== INPUTS =====
    input clk, rst_n,                             // Clock + Reset
    input [31:0] Instr_E,
    
    // ================== ĐẦU VÀO TỪ STAGE ID ==================
    input RegWrite_E,
    input [1:0] ResultSrc_E, // Dung cho hazard
    input MemWrite_E,
    input MemRead_E,     
    input Jump_E,
    input Branch_E,    
    input ALUSrcA_E,
    input ALUSrcB_E,                                        
    input [3:0]  ALUControl_E,
    
    input [2:0]  funct3_E,         
    input [31:0] RD1_E, 
    input [31:0] RD2_E, 
    input [31:0] Imm_Ext_E,
    input [4:0] RS1_E,
    input [4:0] RS2_E,       
    input [4:0]  RD_E,                           
    input [31:0] PC_E, 
    input [31:0] PCPlus4_E,
    // ================== ĐẦU VÀO TỪ STAGE MEM ================== 
    input [31:0] ResultW,      
    // ================== ĐẦU VÀO TỪ HAZARD ==================
    input [1:0]  ForwardA_E, ForwardB_E,         

    // ===== OUTPUTS =====
     // Back ve IF va HAZARD
    output PCSrc_E,                             // Quyết định branch/jump
     // Control Unit stage M
    output RegWrite_M,
    output MemWrite_M,                          // Control signals đến M
    output MemRead_M,
    output [1:0] ResultSrc_M,                   // WB mux control từ M
      // Stage M
    output [2:0]  funct3_M,
    output [4:0]  RD_M,                         // Register đích stage M
    output [31:0] PCPlus4_M, 
    output [31:0] WriteData_M,                  // Dữ liệu ghi Mem + PC+4
    output [31:0] ALU_Result_M,                 // Kết quả ALU để sang M
      // Back ve IF tinh dia chi jump/branch
    output [31:0] ALU_Result_E,
    
    //Debug
    output [31:0] Instr_M
);

    // ================================================================
    // 1. FORWARDING UNIT
    // ================================================================

    // Src_A chọn dữ liệu từ RD1, WB hoặc MEM stage
    reg [31:0] Src_A_interim_reg;
    wire [31:0] Src_A_interim;
    assign Src_A_interim = Src_A_interim_reg;

    always @(*) begin
        case (ForwardA_E)
            2'b00: Src_A_interim_reg = RD1_E;          // Dữ liệu từ register file
            2'b01: Src_A_interim_reg = ResultW;        // Forward từ WB stage
            2'b10: Src_A_interim_reg = ALU_Result_M;   // Forward từ MEM stage
            default: Src_A_interim_reg = 32'bx;
        endcase
    end

    // Src_B_interim chọn dữ liệu từ RD2, WB hoặc MEM stage
    reg [31:0] Src_B_interim_reg;
    wire [31:0] Src_B_interim;
    assign Src_B_interim = Src_B_interim_reg;

    always @(*) begin
        case (ForwardB_E)
            2'b00: Src_B_interim_reg = RD2_E;
            2'b01: Src_B_interim_reg = ResultW;
            2'b10: Src_B_interim_reg = ALU_Result_M;
            default: Src_B_interim_reg = 32'bx;
        endcase
    end
    
    // Src_A chọn giữa register hoặc pc
    wire [31:0] Src_A;
    assign Src_A = ALUSrcA_E ? PC_E : Src_A_interim; 
    // Src_B chọn giữa immediate hoặc register
    wire [31:0] Src_B;
    assign Src_B = ALUSrcB_E ? Imm_Ext_E : Src_B_interim;

    // ================================================================
    // 2. ALU (Arithmetic Logic Unit)
    // ================================================================
    reg [31:0] ALU_Result;
    
    

    always @(*) begin
        case (ALUControl_E)
            4'b0000: ALU_Result = Src_A + Src_B;                           // ADD
            4'b0001: ALU_Result = Src_A - Src_B;                           // SUB
            4'b0010: ALU_Result = Src_A & Src_B;                           // AND
            4'b0011: ALU_Result = Src_A | Src_B;                           // OR
            4'b0100: ALU_Result = Src_A ^ Src_B;                           // XOR
            4'b0101: ALU_Result = ($signed(Src_A) < $signed(Src_B)) ? 32'b1 : 32'b0; // SLT (signed)
            4'b0110: ALU_Result = (Src_A < Src_B) ? 32'b1 : 32'b0;         // SLTU (unsigned)
            4'b0111: ALU_Result = Src_A << Src_B[4:0];                     // SLL
            4'b1000: ALU_Result = Src_A >> Src_B[4:0];                     // SRL (logical)
            4'b1001: ALU_Result = $signed(Src_A) >>> Src_B[4:0];           // SRA (arithmetic)
            4'b1010: ALU_Result = Src_B;                                   // LUI (load upper imm)
            4'b1011: ALU_Result = (Src_A + Src_B) & ~32'b11;               // Branch/Jump Addr (align PC to 4)
        default: ALU_Result = 32'bx;                                   // Unknown
        endcase
    end
    
    assign ALU_Result_E = ALU_Result;
    // ================================================================
    // 3. BRANCH DECISION UNIT
    // ================================================================

    reg Branch_taken;
    wire signed [31:0] S_RS1 = RD1_E;
    wire signed [31:0] S_RS2 = RD2_E;
    
        always @(*) begin
        case (funct3_E)
            3'b000: Branch_taken = (RD1_E == RD2_E);    // BEQ
            3'b001: Branch_taken = (RD1_E != RD2_E);    // BNE
            3'b100: Branch_taken = (S_RS1 < S_RS2);           // BLT (signed)
            3'b101: Branch_taken = (S_RS1 >= S_RS2);          // BGE (signed)
            3'b110: Branch_taken = (RD1_E < RD2_E);     // BLTU (unsigned)
            3'b111: Branch_taken = (RD1_E >= RD2_E);    // BGEU (unsigned)
            default: Branch_taken = 1'b0;                     // Không nhảy nếu funct3 sai
        endcase
    end

    // Quyết định PCSrc_E = Jump hoặc Branch thành công
    assign PCSrc_E = Jump_E | (Branch_E & Branch_taken);

    // ================================================================
    // 4. PIPELINE REGISTER E → M
    // ================================================================
    reg RegWrite_E_r; 
    reg MemWrite_E_r;
    reg MemRead_E_r;
    reg [1:0] ResultSrc_E_r;
    
    reg [4:0] RD_E_r;
    reg [2:0] funct3_E_r;
    reg [31:0] PCPlus4_E_r;
    reg [31:0] Src_B_interim_r;
    reg [31:0] ALU_Result_E_r;
    
    reg [31:0] Instr_M_r;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            RegWrite_E_r    <= 1'b0;
            MemWrite_E_r    <= 1'b0;
            MemRead_E_r     <= 1'b0;
            ResultSrc_E_r   <= 2'b00;
            RD_E_r          <= 5'h0;
            funct3_E_r      <= 3'b0;
            PCPlus4_E_r     <= 32'h0;
            Src_B_interim_r <= 32'h0;
            ALU_Result_E_r   <= 32'h0;
            
            Instr_M_r       <= 32'h0;
        end else begin
            RegWrite_E_r    <= RegWrite_E;
            MemWrite_E_r    <= MemWrite_E;
            MemRead_E_r     <= MemRead_E;
            ResultSrc_E_r   <= ResultSrc_E;
            RD_E_r          <= RD_E;
            funct3_E_r      <= funct3_E;
            PCPlus4_E_r     <= PCPlus4_E;
            Src_B_interim_r <= Src_B_interim;
            ALU_Result_E_r   <= ALU_Result;
            
            Instr_M_r       <= Instr_E;
        end
    end

    // ================================================================
    // 5. OUTPUTS sang stage M
    // ================================================================
    assign RegWrite_M    = RegWrite_E_r;
    assign MemWrite_M    = MemWrite_E_r;
    assign MemRead_M     = MemRead_E_r;
    assign ResultSrc_M   = ResultSrc_E_r;
    assign RD_M          = RD_E_r;
    assign funct3_M      = funct3_E_r;
    assign PCPlus4_M     = PCPlus4_E_r;
    assign WriteData_M   = Src_B_interim_r;
    assign ALU_Result_M  = ALU_Result_E_r;
    
    assign Instr_M       = Instr_M_r;

endmodule
