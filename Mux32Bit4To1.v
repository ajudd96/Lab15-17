`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// ECE369 - Computer Architecture
// 
// Module - Mux32Bit4To1.v
// Description - Performs signal multiplexing between 4 32-Bit words.
////////////////////////////////////////////////////////////////////////////////

module Mux32Bit4To1(out, inA, inB, inC, inD, sel);

    output reg [31:0] out;
    
    input [31:0] inA;
    input [31:0] inB;
    input [31:0] inC;
    input [31:0] inD;
    input [1:0] sel;

    /* Fill in the implementation here ... */
 always @ (sel or inA or inB or inC or inD)
      begin : mux
       case(sel ) 
          2'b00 : out = inA; // if sel = 0, then input A
          2'b01 : out = inB; //if sel = 1,then input B
          2'b10 : out = inC; //if sel = 1,then input B
          2'b11 : out = inD; //if sel = 1,then input B
       endcase 
      end
endmodule
