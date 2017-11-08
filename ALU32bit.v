`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// ECE369 - Computer Architecture
// 
// Module - ALU32Bit.v
// Description - 32-Bit wide arithmetic logic unit (ALU).
//
// INPUTS:-
// ALUControl: 4-Bit input control bits to select an ALU operation.
// A: 32-Bit input port A.
// B: 32-Bit input port B.
//
// OUTPUTS:-
// ALUResult: 32-Bit ALU result output.
// ZERO: 1-Bit output flag. 
//
// FUNCTIONALITY:-
// Design a 32-Bit ALU behaviorally, so that it supports addition,  subtraction,
// AND, OR, and set on less than (SLT). The 'ALUResult' will output the 
// corresponding result of the operation based on the 32-Bit inputs, 'A', and 
// 'B'. The 'Zero' flag is high when 'ALUResult' is '0'. The 'ALUControl' signal 
// should determine the function of the ALU based on the table below:-
// Op   | 'ALUControl' value
// ==========================
// AND  | 000000
// OR   | 000001
// ADD  | 000010
// SLL  | 000011
// SRL  | 000100
// XOR  | 000101
// SUB  | 000110
// SLT  | 000111
// NOR  | 001000
// MUL  | 001001
// MTHI | 001010
// MTLO | 001011
// MFHI | 001100
// MFLO | 001101
// MADD | 001110
// MSUB | 001111
// BEQ  | 010000 ----- Not In
// BGEZ | 010010
// BLEZ | 010011
// BLTZ | 010100
// BNE  | 010101
// SEB	| 010110 ------ New Section
// SEH	| 010111
// ROTR	| 011000
// MOVN	| 011001
// MOVZ	| 011010
// SRA	| 011011
// SLTU	| 011100
//
// MULTU| 011101	
// MULT	| 011110
// ADDU | 011111
// LUI  | 100000

// Test
// NOTE:-
// SLT (i.e., set on less than): ALUResult is '32'h000000001' if A < B.
// 
////////////////////////////////////////////////////////////////////////////////

module ALU32Bit(ALUControl, A, B, Temp_ALUResult, Temp_Zero, Hi, Lo, Temp_64bit_ALUResult);

	input [5:0] ALUControl; 
	input [31:0] A, B, Hi, Lo;	    
	
	output reg [31:0] Temp_ALUResult;
	output reg [63:0] Temp_64bit_ALUResult;
	output reg Temp_Zero;

	// ALU Operations
    parameter ADD = 'b000010, SUB = 'b000110, AND = 'b0000000, ADDU = 'b011111,
              OR = 'b000001, SLT = 'b000111,
              SLL = 'b000011, SRL = 'b000100, XOR = 'b000101,
              NOR = 'b001000, MUL = 'b001001;
	// More Complex Operations
	parameter MTHI = 'b001010, MTLO = 'b001011,
              MFHI = 'b001100, MFLO = 'b001101,
              MADD = 'b001110, MSUB = 'b001111;

	// More Operations
	parameter SEB = 'b010110, SEH = 'b010111, ROTR = 'b011000,
              MOVN = 'b011001, MOVZ = 'b011010, SRA = 'b011011,
              MULT = 'b011110, LUI = 'b100000;
	// Unsigned
	parameter SLTU	= 'b011100, MULTU = 'b011101;

    initial begin
            Temp_ALUResult <= 0;
            Temp_64bit_ALUResult <= 0;
            Temp_Zero <= 0;        
     end
     
	always @(ALUControl, A, B) begin
        case(ALUControl) 
			// Originl Operations
            ADD: begin 
				Temp_ALUResult = $signed(A) + $signed(B);
				if (Temp_ALUResult == 0) begin
					Temp_Zero <= 1;
				end 
				else if (Temp_ALUResult == 1) Temp_Zero <= 0;
				end
            ADDU: Temp_ALUResult = $unsigned(A) + $unsigned(B);
			SUB: Temp_ALUResult = $signed(A) - $signed(B);
            AND: Temp_ALUResult = A & B;
            OR: Temp_ALUResult = A | B;
			SLT: Temp_ALUResult = $signed(A) < $signed(B);
			SLTU: Temp_ALUResult = $unsigned(A) < $unsigned(B); 
            XOR: Temp_ALUResult = A ^ B;
            NOR: Temp_ALUResult = ~(A | B);
            MUL: begin 
				Temp_64bit_ALUResult = $signed(A) * $signed(B); 
				Temp_ALUResult = Temp_64bit_ALUResult[31:0]; // mul does not care about Hi, Lo
			end
			
			MULT: Temp_64bit_ALUResult = $signed(A) * $signed(B);
			MULTU: Temp_64bit_ALUResult = $unsigned(A) * $unsigned(B);
			// (<< and >> inserts zeros)
            SLL: Temp_ALUResult = B << A;
            SRL: Temp_ALUResult = B >> A;
			// Complex Operations
			
			MTHI: Temp_64bit_ALUResult[63:32] = $signed(A); 
            MTLO: Temp_64bit_ALUResult[31:0] = $signed(A); 
            
            MFHI: Temp_ALUResult = $signed(Temp_64bit_ALUResult[63:32]); // Move from High
			MFLO: Temp_ALUResult = $signed(Temp_64bit_ALUResult[31:0]); // Move from Low
			
			MADD: Temp_64bit_ALUResult = $signed( {Hi, Lo}) + ( $signed(A) * $signed(B) );
			MSUB: Temp_64bit_ALUResult = $signed({Hi, Lo}) - ( $signed(A) * $signed(B) );

			SEB: Temp_ALUResult = {{24{B[7]}}, B[7:0]};
            SEH: Temp_ALUResult = {{16{B[15]}}, B[15:0]};
			ROTR: Temp_ALUResult = { {32{1'b0}}, (B << 32-A[4:0]) | (B >> A[4:0])};
			
			// Can be done with SLT and contents moved outside ALU
			MOVN: if(B != 0) Temp_ALUResult <= A; // how to set flag to value with out getting changed
			MOVZ: if(B == 0) Temp_ALUResult <= A; // how to set flag to value with out getting changed
			// ---------------------------------------------
			SRA: Temp_ALUResult <= B >>> A; 
			
			LUI: Temp_ALUResult <= (B << 16);
			
            default: Temp_ALUResult = 32'b0;
        endcase
	end
endmodule
