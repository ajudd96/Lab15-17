`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/24/2017 12:12:19 PM
// Design Name: 
// Module Name: CondMov
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module CondMov(RegWrite, CondMov, Zero, Write);
    
    input RegWrite, CondMov, Zero;
    output reg Write;
    
    //reg And1, And2;
    
    initial begin
        Write <= 0;
    end
    
    always@(RegWrite, CondMov, Zero) begin
        //And1 <= RegWrite & ~CondMov; 
        //And2 <= CondMov  & Zero;
        //Write <= And1 | And2;
        Write <= RegWrite && ~CondMov;
    end

endmodule
