`timescale 1ns/1ps

module fetch_cycle (
    input clk, rst, Stall_F, Stall_D, Flush_D, PCSrc_E,
    input [31:0] PC_Target_E,
    output [31:0] Instr_D, PC_D, PCPlus4_D
);

    wire [31:0] PC_F, PC_next, PC_plus4_F, Instr_F;

    assign PC_next = PCSrc_E ? PC_Target_E : PC_plus4_F;

    reg [31:0] PC_reg;
    always @(posedge clk or negedge rst) begin
        if (!rst) PC_reg <= 32'h0;
        else if (!Stall_F) PC_reg <= PC_next;
    end
    assign PC_F = PC_reg;

    assign PC_plus4_F = PC_F + 32'h4;

    reg [31:0] imem [0:255];
    // initial begin // add code for testing if needed
    // end
    assign Instr_F = imem[PC_F >> 2];

    reg [31:0] Instr_D_reg, PC_D_reg, PCPlus4_D_reg;
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            Instr_D_reg <= 32'h0;
            PC_D_reg <= 32'h0;
            PCPlus4_D_reg <= 32'h0;
        end else if (Flush_D) begin
            Instr_D_reg <= 32'h0;
            PC_D_reg <= 32'h0;
            PCPlus4_D_reg <= 32'h0;
        end else if (!Stall_D) begin
            Instr_D_reg <= Instr_F;
            PC_D_reg <= PC_F;
            PCPlus4_D_reg <= PC_plus4_F;
        end
    end

    assign Instr_D = Instr_D_reg;
    assign PC_D = PC_D_reg;
    assign PCPlus4_D = PCPlus4_D_reg;

endmodule