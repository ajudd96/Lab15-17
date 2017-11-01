`timescale 1ns / 1ps

module IDEX_reg(
//	 	inputs
//			For internal use:
				Clk,
			
//			To Pass through:
//				Control Lines;
					ID_RegWrite,
					ID_CondMov,
					// MemtoReg,
					// MemWrite,
					// MemRead,
					ID_RegDst,
					ID_ALUOp,
					ID_ALUSrc1,
					ID_ALUSrc2,

//				Data lines;
					// ID_PCAddResult,
					ID_ReadData1,
					ID_ReadData2,
					ID_immExt,
					ID_rt,
					ID_rd,
					ID_sa,
				
                
//		outputs
//			To Pass through:
//				Control Lines;
					EX_RegWrite,
					EX_CondMov,
					// EX_MemtoReg,
					// EX_MemWrite,
					// EX_MemRead,
					EX_RegDst,
					EX_ALUOp,
					EX_ALUSrc1,
					EX_ALUSrc2,
					
//				Data lines;
					// EX_PCAddResult,
					EX_ReadData1,
					EX_ReadData2,
					EX_immExt,
					EX_rt,
					EX_rd,
					EX_sa );


input Clk;
input ID_RegWrite, ID_CondMov, ID_RegDst, ID_ALUSrc1, ID_ALUSrc2;
input wire [4:0] ID_ALUOp;
input wire [31:0] ID_ReadData1, ID_ReadData2, ID_immExt, ID_sa;
input wire [4:0] ID_rt, ID_rd;

output reg EX_RegWrite, EX_CondMov, EX_RegDst, EX_ALUSrc1, EX_ALUSrc2;
output reg [4:0] EX_ALUOp;
output reg [31:0] EX_ReadData1, EX_ReadData2, EX_immExt, EX_sa;
output reg [4:0] EX_rt, EX_rd;



always @(posedge Clk) begin
	
	// Controls
	EX_RegWrite <= ID_RegWrite;
	// EX_MemtoReg <= MemtoReg;
	// EX_MemWrite <= MemWrite;
	// EX_MemRead <= MemRead;
	EX_RegDst <= ID_RegDst;
	EX_ALUSrc1 <= ID_ALUSrc1;
	EX_ALUSrc2 <= ID_ALUSrc2;
	EX_ALUOp <= ID_ALUOp;
    EX_CondMov <= ID_CondMov;
	// Data
	// EX_PCAddResult <= ID_PCAddResult;
	EX_ReadData1 <= ID_ReadData1;
	EX_ReadData2 <= ID_ReadData2;
	EX_immExt <= ID_immExt;
	EX_rt <= ID_rt;
	EX_rd <= ID_rd;
	EX_sa <= ID_sa;

	

end
endmodule