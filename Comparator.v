`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Op   | 'ALUControl' value
// ==========================
// BEQ  | 010000 
// BGEZ | 010010
// BLEZ | 010011
// BLTZ | 010100
// BNE  | 010101
// 
//////////////////////////////////////////////////////////////////////////////////


module Comparator(A, B, ALUControl, branchZero);
    
	input [5:0] ALUControl;
    input [31:0] A, B;
    output reg branchZero;
    
	// Comparison
	parameter BEQ = 'b010000, BGTZ = 'b010001, BGEZ = 'b010010,
	          BLEZ = 'b010011, BLTZ = 'b010100, BNE = 'b010101;
	          
	initial begin
		branchZero <= 0;        
	end
	   
	always @(ALUControl, A, B) begin
		case(ALUControl) 
			  // Comparison - ALUResult = 1 when branchZero condition not met
			BEQ: begin 
				if(!(A == B)) branchZero = 0;         
				else branchZero = 1; 
			end
			BGTZ: begin 
				if(A[31] || (A == 0)) branchZero = 0;         
				else if (!(A[31] ) ) branchZero = 1; 
			end
			BGEZ:begin 
				if(A[31]) branchZero = 0;         
				else branchZero = 1; 
			end 
			BLEZ: begin 
				if(!(A[31] || (A == 0))) branchZero = 0;         
				else branchZero = 1; 
			end
			BLTZ: begin 
				if(!(A[31])) branchZero = 0;         
				else branchZero = 1; 
			end
			BNE: begin 
				if(!(A != B))branchZero = 0;         
				else branchZero = 1; 
			end
			default: branchZero = 0;
		endcase
	  end          
endmodule
