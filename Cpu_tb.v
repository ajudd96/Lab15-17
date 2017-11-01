`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////


module Cpu_tb();

reg Clk, reset;
wire [31:0] PCResult, EX_ALUResult, Hi, Lo, WB_ALUResult;
//module CPU(Clk, reset, PCResult, EX_ALUResult, Hi, Lo);
CPU Cpu1(Clk, reset, PCResult, EX_ALUResult, Hi, Lo, WB_ALUResult);

initial begin
		Clk <= 1'b0;
		forever #10 Clk <= ~Clk;
	end
	
initial begin 
	reset <= 1'b1;
	
	#200 reset <= 1'b0;

end
endmodule
