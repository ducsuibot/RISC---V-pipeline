`timescale 1ns/1ps

module hazard_unit (
    // ================== ĐẦU VÀO /RA TỪ STAGE IF ==================
    output Stall_F, Stall_D, Flush_D, 
    // ================== ĐẦU VÀO /RA TỪ STAGE DECODE ==================
    input [4:0] RS1_D, RS2_D,
    output Flush_E,
    // ================== ĐẦU VÀO / RA TỪ STAGE EX ==================
    input [4:0] RS1_E, RS2_E, RD_E,
    input [1:0] ResultSrc_E,
    input PCSrc_E,
    output reg [1:0] ForwardA_E, ForwardB_E,
    // ================== ĐẦU VÀO / RA TỪ STAGE MEMORY ==================
    input [4:0] RD_M,
    input RegWrite_M, 
    // ================== ĐẦU VÀO / RA TỪ STAGE WRITEBACK ==================
    input [4:0] RD_W,
    input RegWrite_W
);

    always @(*) begin
        if ((RS1_E == RD_M) & RegWrite_M & (RS1_E != 5'b0)) ForwardA_E = 2'b10;
        else if ((RS1_E == RD_W) & RegWrite_W & (RS1_E != 5'b0)) ForwardA_E = 2'b01;
        else ForwardA_E = 2'b00;
    end

    always @(*) begin
        if ((RS2_E == RD_M) & RegWrite_M & (RS2_E != 5'b0)) ForwardB_E = 2'b10;
        else if ((RS2_E == RD_W) & RegWrite_W & (RS2_E != 5'b0)) ForwardB_E = 2'b01;
        else ForwardB_E = 2'b00;
    end

    wire lw_Stall = ResultSrc_E[0] & ((RD_E == RS1_D) | (RD_E == RS2_D));

    assign Stall_F = lw_Stall;
    assign Stall_D = lw_Stall;
    assign Flush_D = PCSrc_E;
    assign Flush_E = lw_Stall | PCSrc_E;

endmodule