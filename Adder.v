`timescale 1ns / 1ps

module Adder32Bit(in1, in2, out);

    input [31:0] in1, in2;

    output reg [31:0] out;

    always @ (in1, in2)
        begin
            out <= in1 + in2;
        end

endmodule
