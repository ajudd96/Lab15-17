`timescale 1ns / 1ps

module MEMWB_reg(
//		inputs
//			For internal use:
				Clk,

//			To Pass through:
//				Control lines;
					MEM_RegWrite,
				    MEM_CondMov,
				    MEM_MemtoReg,
				    
//				Data lines;
					MEM_ZeroFlag,
					MEM_ALUResult,
					MEM_WriteRegister,
					MEM_MemData,
					

//		outputs
//			To pass through:
// 				Control lines;
					WB_RegWrite,
				    WB_CondMov,
				    
//				Data lines;	
                    WB_ZeroFlag,			
					WB_ALUResult,
					WB_WriteRegister,
					WB_MemData,
					WB_MemtoReg );

input Clk;
input MEM_RegWrite, MEM_ZeroFlag;
input wire MEM_CondMov, MEM_MemtoReg;
input wire [31:0] MEM_ALUResult, MEM_MemData;
input wire [4:0]  MEM_WriteRegister; 

output reg WB_RegWrite, WB_ZeroFlag;
output reg WB_CondMov, WB_MemtoReg;
output reg [31:0] WB_ALUResult, WB_MemData;
output reg [4:0]  WB_WriteRegister;

initial begin
    WB_RegWrite = 0;
    WB_ZeroFlag = 0;
    WB_CondMov = 0;
end

always @(posedge Clk) begin
	
	// Control
	WB_RegWrite <= MEM_RegWrite;
	WB_ZeroFlag <= MEM_ZeroFlag;
	WB_CondMov <= MEM_CondMov;
	WB_MemtoReg <= MEM_MemtoReg;
	// Data
	WB_ALUResult <= MEM_ALUResult;
	WB_WriteRegister <= MEM_WriteRegister;
	WB_MemData <= MEM_MemData;

end
endmodule