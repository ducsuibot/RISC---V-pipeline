`timescale 1ns/1ps

module hazard_unit (
    input [4:0] RS1_D, RS2_D, RS1_E, RS2_E, Rd_E, Rd_M, Rd_W,
    input RegWrite_M, RegWrite_W,
    input [1:0] ResultSrc_E,
    input PCSrc_E,
    output reg [1:0] ForwardA_E, ForwardB_E,
    output Stall_F, Stall_D, Flush_D, Flush_E
);

    always @(RS1_E) begin
        if ((RS1_E == Rd_M) & RegWrite_M & (RS1_E != 5'b0)) ForwardA_E = 2'b10;
        else if ((RS1_E == Rd_W) & RegWrite_W & (RS1_E != 5'b0)) ForwardA_E = 2'b01;
        else ForwardA_E = 2'b00;
    end

    always @(RS2_E) begin
        if ((RS2_E == Rd_M) & RegWrite_M & (RS2_E != 5'b0)) ForwardB_E = 2'b10;
        else if ((RS2_E == Rd_W) & RegWrite_W & (RS2_E != 5'b0)) ForwardB_E = 2'b01;
        else ForwardB_E = 2'b00;
    end

    wire lw_Stall = ResultSrc_E[0] & ((Rd_E == RS1_D) | (Rd_E == RS2_D));

    assign Stall_F = lw_Stall;
    assign Stall_D = lw_Stall;
    assign Flush_D = PCSrc_E;
    assign Flush_E = lw_Stall | PCSrc_E;

endmodule