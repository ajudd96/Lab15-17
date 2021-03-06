`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// ECE369 - Computer Architecture
// 
// Module - data_memory.v
// Description - 32-Bit wide data memory.
//
// INPUTS:-
// Address: 32-Bit address input port.
// WriteData: 32-Bit input port.
// Clk: 1-Bit Input clock signal.
// MemWrite: 1-Bit control signal for memory write.
// MemRead: 1-Bit control signal for memory read.
//
// OUTPUTS:-
// ReadData: 32-Bit registered output port.
//
// FUNCTIONALITY:-
// Design the above memory similar to the 'RegisterFile' model in the previous 
// assignment.  Create a 1K memory, for which we need 10 bits.  In order to 
// implement byte addressing, we will use bits Address[11:2] to index the 
// memory location. The 'WriteData' value is written into the address 
// corresponding to Address[11:2] in the positive clock edge if 'MemWrite' 
// signal is 1. 'ReadData' is the value of memory location Address[11:2] if 
// 'MemRead' is 1, otherwise, it is 0x00000000. The reading of memory is not 
// clocked.
//
// you need to declare a 2d array. in this case we need an array of 1024 (1K)  
// 32-bit elements for the memory.   
// for example,  to declare an array of 256 32-bit elements, declaration is: reg[31:0] memory[0:255]
// if i continue with the same declaration, we need 8 bits to index to one of 256 elements. 
// however , address port for the data memory is 32 bits. from those 32 bits, least significant 2 
// bits help us index to one of the 4 bytes within a single word. therefore we only need bits [9-2] 
// of the "Address" input to index any of the 256 words. 
////////////////////////////////////////////////////////////////////////////////

module DataMemory(Address, WriteData, Clk, MemWrite, MemRead, ModeControl, ReadData); 

    input [31:0] Address; 	// Input Address 
    input [31:0] WriteData; // Data that needs to be written into the address 
    input Clk;
	input [1:0] ModeControl;
    input MemWrite; 		// Control signal for memory write 
    input MemRead; 			// Control signal for memory read 

    output reg[31:0] ReadData; // Contents of memory location at Address
	
	parameter WordMode ='b00, HalfwordMode = 'b01, ByteMode = 'b10;
    reg[31:0] memory[0:1023];
    
    integer i;
    initial begin
            memory[0] = 32'd0;
            memory[1] = 32'd1;
            memory[2] = 32'd2;
            memory[3] = 32'd3;
            memory[4] = 32'd4;
            memory[5] = -32'd1;
            for(i=6; i<1024; i=i+1) begin
                memory[i] <= 32'h00000000;
            end        
    end
    
    always @(Address, WriteData, MemWrite, MemRead, ModeControl) begin   // non-Clocked Read function see lines 26 - 27
         if(MemRead) begin
				case(ModeControl)
					WordMode:  ReadData = memory[Address[11:2]];
					HalfwordMode:	begin
										if(Address[1]==1'b0) ReadData ={ {16{memory[Address[11:2]][31]}}, {16{1'b0}} } | ((memory[Address[11:2]] & 'b1111_1111_1111_1111_0000_0000_0000_0000) >> 16);
										else if(Address[1]==1'b1) ReadData =  { {16{memory[Address[11:2]][31]}}, {16{1'b0}} }  | ((memory[Address[11:2]]) & 32'b0000_0000_0000_0000_1111_1111_1111_1111);
									end
					ByteMode:	begin
									if(Address[1:0]==2'b00) ReadData =  { {24{memory[Address[11:2]][31]}}, {8{1'b0}} } | ((memory[Address[11:2]] & 32'b1111_1111_0000_0000_0000_0000_0000_0000) >> 24);
									else if(Address[1:0]==2'b01) ReadData = { {24{memory[Address[11:2]][23]}}, {8{1'b0}} } | ((memory[Address[11:2]] & 32'b0000_0000_1111_1111_0000_0000_0000_0000) >> 16);
									else if(Address[1:0]==2'b10) ReadData = { {24{memory[Address[11:2]][16]}}, {8{1'b0}} } | ((memory[Address[11:2]] & 32'b0000_0000_0000_0000_1111_1111_0000_0000) >> 8);
									else if(Address[1:0]==2'b11) ReadData = { {24{memory[Address[11:2]][8]}}, {8{1'b0}} } | (memory[Address[11:2]] & 32'b0000_0000_0000_0000_0000_0000_1111_1111);
								end
				endcase
         end
         else begin
                 ReadData = 'h00000000;
        end
    end
    
    always @(posedge Clk) begin
            if  (MemWrite) begin
					case(ModeControl)
						WordMode:	begin
										memory[Address[11:2]] = WriteData;
									end
						HalfwordMode:	begin
											if(Address[1]=='b0) memory[Address[11:2]] = (memory[Address[11:2]] & 32'b0000_0000_0000_0000_1111_1111_1111_1111) | (WriteData << 16);
											if(Address[1]=='b1) memory[Address[11:2]] = (memory[Address[11:2]] & 32'b1111_1111_1111_1111_0000_0000_0000_0000) | WriteData;
										end
						ByteMode:	begin
										if(Address[1:0]=='b00) memory[Address[11:2]] = (memory[Address[11:2]] & 32'b0000_0000_1111_1111_1111_1111_1111_1111) | (WriteData << 24);
										else if(Address[1:0]=='b01) memory[Address[11:2]] = (memory[Address[11:2]] & 32'b1111_1111_0000_0000_1111_1111_1111_1111) | (WriteData << 16);
										else if(Address[1:0]=='b10) memory[Address[11:2]] = (memory[Address[11:2]] & 32'b1111_1111_1111_1111_0000_0000_1111_1111) | (WriteData << 8);
										else if(Address[1:0]=='b11) memory[Address[11:2]] = (memory[Address[11:2]] & 32'b1111_1111_1111_1111_1111_1111_0000_0000) | WriteData;
									end
					endcase
            end
    end
    
endmodule
