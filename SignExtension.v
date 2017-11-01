`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// ECE369 - Computer Architecture
// 
// Module - SignExtension.v
// Description - Sign extension module.
////////////////////////////////////////////////////////////////////////////////

module SignExtension(in, out, SignExt);

    /* A 16-Bit input word */
    input [15:0] in;

    input SignExt;	// SignExt == 1, sign extend
    				// SignExt == 0, zero extend
    
    /* A 32-Bit output word */
    output [31:0] out;
    
    /* Fill in the implementation here ... */
    reg [31:0] out;
    
always @(in, SignExt) begin
	if (SignExt) begin
		out[15:0] = in[15:0];
    	out[31:16] = {16{out[15]}};
	end
	else begin
		out[15:0] = in[15:0];
		out[31:16] = 'b0000000000000000;
	end
    
end
endmodule
