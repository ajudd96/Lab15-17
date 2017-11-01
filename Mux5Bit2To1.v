`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// ECE369 - Computer Architecture
// 
// Module - Mux5Bit2To1.v
// Description - Performs signal multiplexing between 2 5bit words.
////////////////////////////////////////////////////////////////////////////////

module Mux5Bit2To1(out, inA, inB, sel);

    output reg [4:0] out;
    
    input [4:0] inA;
    input [4:0] inB;
    input sel;

    /* Fill in the implementation here ... */
 always @ (sel or inA or inB)
      begin : mux
       case(sel ) 
          1'b0 : out = inA; // if sel = 0, then input A
          1'b1 : out = inB; //if sel = 1,then input B
       endcase 
      end
endmodule
