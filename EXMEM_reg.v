`timescale 1ns / 1ps

module EXMEM_reg(
//		inputs
//			For internal use:
				Clk,
				
//			To pass through:
//				Control lines;
					EX_RegWrite,
					EX_CondMov,
					EX_MemtoReg,
					EX_MemWrite,
					EX_MemRead,
					EX_JumpMux, 	// new
					EX_DMControl,	// new
					EX_Branch,
					
//				Data lines;
                    EX_ZeroFlag,
					EX_AdderResult,	// new
					EX_ALUResult,
					EX_WriteRegister, // new
					EX_JumpAddress,	// new
					EX_PCAddResult,	// new
					EX_ReadData1,  	// new
					EX_ReadData2,	// new

//		outputs
//			To pass through:
//				Control lines;
					MEM_RegWrite,
					MEM_CondMov,
					MEM_MemtoReg,
					MEM_MemWrite,
					MEM_MemRead,
					MEM_JumpMux,
					MEM_DMControl,
					MEM_Branch,
				
//				Data lines;
                    MEM_ZeroFlag,
					MEM_AdderResult,
					MEM_ALUResult,
					MEM_WriteRegister,
					MEM_JumpAddress,
					MEM_PCAddResult,
					MEM_ReadData1,
					MEM_ReadData2 );

input Clk;
input EX_RegWrite, EX_CondMov;
input wire EX_ZeroFlag, EX_MemtoReg, EX_MemWrite, EX_MemRead, EX_Branch;
input wire [1:0] EX_JumpMux, EX_DMControl;
input wire [31:0] EX_ALUResult, EX_AdderResult, EX_JumpAddress, EX_PCAddResult, EX_ReadData1, EX_ReadData2;
input wire [4:0]  EX_WriteRegister; 


output reg MEM_RegWrite, MEM_CondMov;
output reg MEM_ZeroFlag, MEM_MemtoReg, MEM_MemWrite, MEM_MemRead, MEM_Branch;
output reg [1:0] MEM_JumpMux, MEM_DMControl;
output reg [31:0] MEM_ALUResult, MEM_AdderResult, MEM_JumpAddress, MEM_PCAddResult, MEM_ReadData1, MEM_ReadData2;
output reg [4:0]  MEM_WriteRegister;

initial begin
    MEM_RegWrite = 0;
    MEM_CondMov = 0;
    MEM_ZeroFlag = 0;
    MEM_MemWrite = 0;
    MEM_MemRead = 0;
    MEM_JumpMux = 'b00;
    MEM_Branch = 0;
end

always @(posedge Clk) begin
	
	// Control
	MEM_RegWrite <= EX_RegWrite;
	MEM_CondMov <= EX_CondMov;
	MEM_MemtoReg <= EX_MemtoReg;
	MEM_MemWrite <= EX_MemWrite;
	MEM_MemRead <= EX_MemRead;
	MEM_JumpMux <= EX_JumpMux;
	MEM_DMControl <= EX_DMControl;
	MEM_Branch <= EX_Branch;
	
	// Data
	MEM_ZeroFlag <= EX_ZeroFlag;
	MEM_ALUResult <= EX_ALUResult;
	MEM_AdderResult <= EX_AdderResult;
	MEM_WriteRegister <= EX_WriteRegister;
	MEM_JumpAddress <= EX_JumpAddress;
	MEM_PCAddResult <= EX_PCAddResult;
	MEM_ReadData1 <= EX_ReadData1;
	MEM_ReadData2 <= EX_ReadData2;

end
endmodule