`timescale 1ns / 1ps

module EXMEM_reg(
//		inputs
//			For internal use:
				Clk,
				
//			To pass through:
//				Control lines;
					EX_RegWrite,
					EX_CondMov,
					// EX_MemtoReg,
					// EX_MemWrite,
					// EX_MemRead,
					
//				Data lines;
                    EX_ZeroFlag,
					// EX_AdderResult,
					EX_ALUResult,
					// EX_ReadData2,
					EX_WriteRegister,


//		outputs
//			To pass through:
//				Control lines;
					MEM_RegWrite,
					MEM_CondMov,
					// MEM_MemtoReg,
					// MEM_MemWrite,
					// MEM_MemRead,
				
//				Data lines;
                    MEM_ZeroFlag,
					// MEM_AdderResult,
					MEM_ALUResult,
					// MEM_ReadData2,
					MEM_WriteRegister );

input Clk;
input EX_RegWrite, EX_CondMov;
input wire EX_ZeroFlag;
input wire [31:0] EX_ALUResult;
input wire [4:0]  EX_WriteRegister; 


output reg MEM_RegWrite, MEM_CondMov;
output reg MEM_ZeroFlag;
output reg [31:0] MEM_ALUResult;
output reg [4:0]  MEM_WriteRegister;

initial begin
    MEM_RegWrite = 0;
    MEM_CondMov = 0;
    MEM_ZeroFlag = 0;
end

always @(posedge Clk) begin
	
	// Control
	MEM_RegWrite <= EX_RegWrite;
	MEM_CondMov <= EX_CondMov;
	
	// Data
	MEM_ZeroFlag <= EX_ZeroFlag;
	MEM_ALUResult <= EX_ALUResult;
	MEM_WriteRegister <= EX_WriteRegister;

end
endmodule