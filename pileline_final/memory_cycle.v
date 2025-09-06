`timescale 1ns/1ps

module memory_cycle (
    // ===== INPUTS =====
    input clk, rst_n,                        // Clock & Reset Active Low
    
    input [31:0] Instr_M,
   
    // ================== ĐẦU VÀO TỪ STAGE EX ==================
    input RegWrite_M,                     // Tín hiệu ghi register từ stage M
    input MemWrite_M,                     // Tín hiệu ghi bộ nhớ từ stage M
    input MemRead_M,
    input [1:0] ResultSrc_M,              // Chọn dữ liệu WB: ALU, DMEM, hoặc PC+4
    
    input [2:0] funct3_M,
    input [4:0] RD_M,                     // Thanh ghi đích từ stage M
    input [31:0] PCPlus4_M,               // PC + 4 (trả về WB nếu cần)
    input [31:0] WriteData_M,             // Dữ liệu cần ghi vào DMEM
    input [31:0] ALU_Result_M,            // Địa chỉ bộ nhớ từ ALU
    
    // ===== OUTPUTS =====
    output RegWrite_W,                    // Truyền tín hiệu ghi reg sang stage W
    output [1:0] ResultSrc_W,             // Truyền ResultSrc sang stage W
    output [4:0] RD_W,                    // Thanh ghi đích WB
    output [31:0] PCPlus4_W,              // PC + 4 WB
    output [31:0] ALU_Result_W,           // Giá trị ALU sang WB
    output [31:0] ReadData_W,              // Dữ liệu đọc từ DMEM sang WB
    
    output [31:0] Instr_W
);

    // =========================================================
    // 1. DATA MEMORY (DMEM)
    // =========================================================
    // Kích thước 256 words (1 word = 32-bit)
    reg [7:0] data_mem [0:4095];
    wire [11:0] byte_addr = ALU_Result_M[11:0];
    integer i = 0;
    // Ghi bộ nhớ tại địa chỉ = ALU_Result_M >> 2 (địa chỉ word-aligned)
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            for (i = 0; i < 4096; i = i + 1) begin
              data_mem[i] <= 8'h0;
            end
        end
        else if (MemWrite_M) begin
          case(funct3_M) 
                3'b000: data_mem[byte_addr] <= WriteData_M[7:0];     // SB
                3'b001: begin                                        // SH
                    data_mem[byte_addr]   <= WriteData_M[7:0];
                    data_mem[byte_addr+1] <= WriteData_M[15:8];
                end
                3'b010: begin                                       // SW
                    data_mem[byte_addr]   <= WriteData_M[7:0];
                    data_mem[byte_addr+1] <= WriteData_M[15:8];
                    data_mem[byte_addr+2] <= WriteData_M[23:16];
                    data_mem[byte_addr+3] <= WriteData_M[31:24];
                end 
                default: ;
           endcase 
        end
    end

    // Đọc bộ nhớ (read-only, combinational)
    // Dữ liệu đọc từ DMEM tại stage M
    reg [31:0] ReadData_M;
        always @(*) begin
        if (MemRead_M) begin
            case (funct3_M)
                3'b000: ReadData_M = {{24{data_mem[byte_addr][7]}}, data_mem[byte_addr]}; // LB
                3'b001: ReadData_M = {{16{data_mem[byte_addr+1][7]}},
                                   data_mem[byte_addr+1], data_mem[byte_addr]};           // LH
                3'b010: ReadData_M = {data_mem[byte_addr+3], data_mem[byte_addr+2],
                                   data_mem[byte_addr+1], data_mem[byte_addr]};           // LW
                3'b100: ReadData_M = {24'b0, data_mem[byte_addr]};                        // LBU
                3'b101: ReadData_M = {16'b0, data_mem[byte_addr+1], data_mem[byte_addr]}; // LHU
                default: ReadData_M = 32'bx;
            endcase
        end else begin
            ReadData_M = 32'bx;
        end
    end

    // =========================================================
    // 2. PIPELINE REGISTER M → W (Stage Memory → Stage Writeback)
    // =========================================================
    // Các thanh ghi pipeline lưu tín hiệu điều khiển và dữ liệu
    reg RegWrite_W_r;
    reg [1:0] ResultSrc_W_r;
    
    reg [4:0] RD_W_r;
    
    reg [31:0] PCPlus4_W_r;
    reg [31:0] ALU_Result_W_r;
    reg [31:0] ReadData_W_r;
    
    reg [31:0] Instr_W_r;

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            // Reset toàn bộ pipeline W về giá trị 0
            RegWrite_W_r    <= 1'b0;
            ResultSrc_W_r   <= 2'b00;
            RD_W_r          <= 5'h0;
            PCPlus4_W_r     <= 32'h0;
            ALU_Result_W_r  <= 32'h0;
            ReadData_W_r    <= 32'h0;
            
            Instr_W_r       <= 32'h0;
        end else begin
            // Ghi dữ liệu từ stage M sang stage W
            RegWrite_W_r    <= RegWrite_M;
            ResultSrc_W_r   <= ResultSrc_M;
            RD_W_r          <= RD_M;
            PCPlus4_W_r     <= PCPlus4_M;
            ALU_Result_W_r  <= ALU_Result_M;
            ReadData_W_r    <= ReadData_M;
            
            Instr_W_r       <= Instr_M;
        end
    end

    // =========================================================
    // 3. OUTPUTS sang Stage W
    // =========================================================
    assign RegWrite_W   = RegWrite_W_r;     // Control WB
    assign ResultSrc_W  = ResultSrc_W_r;    // WB mux control
    assign RD_W         = RD_W_r;           // Thanh ghi WB
    assign PCPlus4_W    = PCPlus4_W_r;      // PC+4 sang WB
    assign ALU_Result_W = ALU_Result_W_r;   // Kết quả ALU sang WB
    assign ReadData_W   = ReadData_W_r;     // Dữ liệu đọc từ DMEM sang WB
    
    assign Instr_W      = Instr_W_r;

endmodule
