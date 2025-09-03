`timescale 1ns/1ps

module writeback_cycle (
    input [1:0] ResultSrc_W,
    input [31:0] PCPlus4_W, ALU_Result_W, ReadData_W,
    output [31:0] Result_W
);
    // từ tín hiệu ResultSrc thì ta chọn 1 trong 3 đầu vào
    reg [31:0] Result_W_reg;
    always @(ResultSrc_W) begin
        case (ResultSrc_W)
            2'b00: Result_W_reg = ALU_Result_W;
            2'b01: Result_W_reg = ReadData_W;
            2'b10: Result_W_reg = PCPlus4_W;
            default: Result_W_reg = 32'bx;
        endcase
    end
    assign Result_W = Result_W_reg;

endmodule