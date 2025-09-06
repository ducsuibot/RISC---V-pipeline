`timescale 1ns/1ps

module writeback_cycle (
    input         RegWrite_W,
    input [1:0]   ResultSrc_W,
    input [4:0]   RD_W,
    input [31:0]  PCPlus4_W,
    input [31:0]  ALU_Result_W, 
    input [31:0]  ReadData_W,
    output [31:0] Result_W
);

    reg [31:0] Result_W_reg;
    always @(*) begin
        case (ResultSrc_W)
            2'b00: Result_W_reg = ALU_Result_W;
            2'b01: Result_W_reg = ReadData_W;
            2'b10: Result_W_reg = PCPlus4_W;
            default: Result_W_reg = 32'bx;
        endcase
    end
    assign Result_W = Result_W_reg;

endmodule
