`timescale 1ns / 1ps

////////////////////////////////////////////
////////////////////////////////////////
module AndModule(ina, inb, out);
input ina, inb;
output reg out;

always @(ina, inb) begin
	out = ina & inb;
end

endmodule