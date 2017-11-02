`timescale 1ns / 1ps

/////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////
module Control(
               // input data
               Op, Funct, InstructionBit_6, InstructionBit_9, InstructionBit_21, rt, 
              
              // output signals
               Branch, MemRead, MemtoReg, MemWrite,
               RegDst, ALUSrc2, RegWrite, SignExt, CondMov, ALUSrc1, 
               ALUControl, DMControl, WriteDst, JumpMux );  

	input [5:0] Op; // control bits for ALU operation
    input [5:0] Funct;  // to determine ALUControl for r-type operations
    // To help differentiate instuctions that have the same OpCode and functCode
        input InstructionBit_6;         // to differentiate between ROTRV or SRLV
        input InstructionBit_9;         // to differentiate between SEB and SEH
        input InstructionBit_21;        // to differentiate between ROTR and SRL
    input [4:0] rt;                        // to differentiate between BGEZ and BLTZ 

	// Control Signals
	output reg RegDst;	    // chooses between rt(RegDst == 0) and rd(RegDst ==1)
                            // for the WriteRegister address input to RegisterFile
	output reg Branch;		// Branch == 1 if branch instruction, 0 if anything else
	output reg MemRead;		// MemRead == 1 if lw, 0 if anything else
	output reg MemtoReg;	// chooses between DM Read Data output(MemtoReg == 0)
                            // and ALUResult(MemtoReg == 1) for WriteData input to RegisterFile
	output reg MemWrite;	// MemWrite == 1 if sw and 0 if anything else 
	output reg ALUSrc2;	// chooses between R[rt](ALUSrc == 0) and immExt(ALUSrc == 1) for ALU input B
    output reg ALUSrc1;     // chooses between R[rs] (ALUSrc ==0) and sa(shift amount)(ALUSrc == 1) for ALU input A
	output reg RegWrite;	// RegWrite == 1 if r-type or lw instruction and 0 if sw or branch 
	output reg SignExt;		// SignExt == 1 if Sign Extend requires sign extension, 0 for 0 extension (unsigned numbers)
    output reg CondMov;   // CondMov == 1 if movn or movz. This bit is ANDed with ALU ZeroFlag
                            // and ORed with RegWrite signal
    output reg [1:0] WriteDst;  // Controls 4 to 1 mux to Write Data port of regfile
        // 'WriteDst' value | Source
        // ==========================
        // 00   | Output of MemtoReg mux
        // 01   | register $31
        // 10   | unused
        // 11   | PC + 4 value

    output reg [1:0] JumpMux;
        // 'JumpMux' value | Source
        // ==========================
        // 00   | Output of PcSrc mux
        // 01   | R[rs]
        // 10   | Jump Address
        // 11   | PC + 4 value
                          
    output reg [5:0] ALUControl;        // changed from 5 bit to 6 bit 11/1/17
        // Op   | 'ALUControl' value
        // ==========================
        // AND  | 000000
        // OR   | 000001
        // ADD  | 000010
        // SHL  | 000011
        // SHR  | 000100
        // XOR  | 000101
        // SUB  | 000110
        // SLT  | 000111
        // NOR  | 001000  
        // MUL  | 001001
        // MOVTH| 001010
        // MOVTL| 001011
        // MFHI | 001100
        // MFLO | 001101
        // MADD | 001110
        // MSUB | 001111
        // BEQ  | 010000
        // BGTZ | 010001
        // BGEZ | 010010
        // BLEZ | 010011
        // BLTZ | 010100
        // BNE  | 010101
        // SEB  | 010110 ------ New Section
        // SEH  | 010111
        // ROTR | 011000
        // MOVZ | 011010
        // SRA  | 011011
        // SLTU | 011100
        // MULTU| 011101 
        // MULT | 011110
        // ADDU | 011111
        // LUI  | 100000

output reg [1:0] DMControl; 
        // 'DMControl' value | Operation
        // ==========================
        // 00   | Word mode
        // 01   | Half-word mode
        // 10   | Byte-mode
        // 11   | n/a

                /* OP Field codes */
    parameter 	RTYPE = 'b000000, SW = 'b101011, SB = 'b101000, SH = 'b101001,
    			LW = 'b100011, LB = 'b100000, LH ='b100001, LUI = 'b001111,
     	   	    BEQ = 'b000100, BNE = 'b000101, BGTZ = 'b000111, BLEZ = 'b000110, BLTZ_BGEZ= 'b000001,
     	   	    J = 'b000010, JAL = 'b000011, 
     	   	    ADDI = 'b001000, ADDIU = 'b001001, ANDI = 'b001100, ORI = 'b001101, XORI = 'b001110, 
     	   	    SLTI = 'b001010,
                MADD_SUB_MUL = 'b011100, SLTIU = 'b001011, SEB_SEH = 'b011111;

                /* Function field codes */
    parameter   ADD = 'b100000, SUB = 'b100010, AND = 'b100100, OR = 'b100101, XOR = 'b100110, NOR = 'b100111,
                SLT = 'b101010, MULT = 'b011000, MULTU = 'b011001, MTHI = 'b010001, MTLO = 'b010011, MFHI = 'b010000, MFLO = 'b010010,
                SLL = 'b000000, ROTR_SRL = 'b000010, SLLV = 'b000100, ROTRV_SRLV = 'b000110,
                MOVN = 'b001011, MOVZ = 'b001010, ROTRV = 'b000110, SRA = 'b000011, SRAV = 'b000111, 
                SLTU = 'b101011, MADD = 'b000000, MSUB = 'b000100, MUL = 'b000010, ADDU = 'b100001,
                JR = 'b001000;         

    initial begin 
          // initializing all output signals to zero
          RegDst = 0;
          Branch <= 0;
          MemRead <= 0;
          MemtoReg <= 0;
          MemWrite <= 0;
          ALUSrc2 = 0;
          ALUControl = 'b000000;  
          CondMov = 'b0;
          ALUSrc1 = 'b0;
          RegWrite = 0;  
          SignExt = 0;   
          DMControl <= 'b00;
          WriteDst = 'b00;
          JumpMux = 'b00;    
    end


    always @(Op, Funct, /*InstructionBit_6, InstructionBit_9, InstructionBit_21*/) begin
  

        case(Op)
        	RTYPE: begin
                case(Funct)
                   /* ADD: begin
                        RegDst <= 1;
                        Branch <= 0;
                        MemRead <= 0;
                        MemtoReg <= 1;
                        MemWrite <= 0; 
                        ALUSrc2 <= 0;
                        ALUSrc1 <= 0;
                        RegWrite <= 1;   
                        SignExt <= 0;   // don't care
                        CondMov <= 0;    
                        ALUControl <= 'b000010;
                        DMControl <= 'b00;
                        WriteDst <= 'b00;
                        JumpMux <= 'b00;
                    end
                      ADDU: begin
                           RegDst <= 1;
                           Branch <= 0;
                           MemRead <= 0;
                           MemtoReg <= 1;
                           MemWrite <= 0; 
                           ALUSrc2 <= 0;
                           ALUSrc1 <= 0;
                           RegWrite <= 1;   
                           SignExt <= 0;   // don't care
                           JumpMux = 'b00;
                           CondMov <= 0;    
                           ALUControl <= 'b011111;
                           DMControl <= 'b00;
                           WriteDst <= 'b00;
                       end
                    SUB: begin
                        RegDst <= 1;
                        Branch <= 0;
                        MemRead <= 0;
                        MemtoReg <= 1;
                        MemWrite <= 0;
                        ALUSrc2 <= 0;
                        ALUSrc1 <= 0;
                        RegWrite <= 1;   
                        SignExt <= 0;   // don't care
                        JumpMux = 'b00;
                        CondMov <= 0;
                        ALUControl <= 'b000110;
                        DMControl <= 'b00;
                        WriteDst <= 'b00;
                    end
                    AND: begin
                        RegDst <= 1;
                        Branch <= 0;
                        MemRead <= 0;
                        MemtoReg <= 1;
                        MemWrite <= 0;
                        ALUSrc2 <= 0;
                        ALUSrc1 <= 0;
                        RegWrite <= 1;   
                        SignExt <= 0;   // don't care
                        JumpMux = 'b00;
                        CondMov <= 0;
                        ALUControl <= 'b000000;
                        DMControl <= 'b00;
                        WriteDst <= 'b00;
                    end
                    OR: begin
                        RegDst <= 1;
                        Branch <= 0;
                        MemRead <= 0;
                        MemtoReg <= 1;
                        MemWrite <= 0;
                        ALUSrc2 <= 0;
                        ALUSrc1 <= 0;
                        RegWrite <= 1;   
                        SignExt <= 0;   // don't care
                        JumpMux = 'b00;
                        CondMov <= 0;
                        ALUControl <= 'b000001;
                        DMControl <= 'b00;
                        WriteDst <= 'b00;
                    end
                    XOR: begin
                        RegDst <= 1;
                        Branch <= 0;
                        MemRead <= 0;
                        MemtoReg <= 1;
                        MemWrite <= 0;
                        ALUSrc2 <= 0;
                        ALUSrc1 <= 0;
                        RegWrite <= 1;   
                        SignExt <= 0;   // don't care
                        JumpMux = 'b00;
                        CondMov <= 0;
                        ALUControl <= 'b000101;
                        DMControl <= 'b00;
                        WriteDst <= 'b00;
                    end
                    NOR: begin
                        RegDst <= 1;
                        Branch <= 0;
                        MemRead <= 0;
                        MemtoReg <= 1;
                        MemWrite <= 0;
                        ALUSrc2 <= 0;
                        ALUSrc1 <= 0;
                        RegWrite <= 1;   
                        SignExt <= 0;   // don't care
                        JumpMux = 'b00;
                        CondMov <= 0;
                        ALUControl <= 'b001000;
                        DMControl <= 'b00;
                        WriteDst <= 'b00;
                    end

                    MULT: begin
                        RegDst <= 1;
                        Branch <= 0;
                        MemRead <= 0;
                        MemtoReg <= 1;
                        MemWrite <= 0;
                        ALUSrc2 <= 0;
                        ALUSrc1 <= 0;
                        RegWrite <= 0;   
                        SignExt <= 0;   // don't care
                        JumpMux = 'b00;
                        CondMov <= 0;
                        ALUControl <= 'b011110;
                        DMControl <= 'b00;
                        WriteDst <= 'b00;
                    end
                    MULTU: begin
                        RegDst <= 1;
                        Branch <= 0;
                        MemRead <= 0;
                        MemtoReg <= 1;
                        MemWrite <= 0;
                        ALUSrc2 <= 0;
                        ALUSrc1 <= 0;
                        RegWrite <= 1;   
                        SignExt <= 0;   // don't care
                        JumpMux = 'b00;
                        CondMov <= 0;
                        ALUControl <= 'b011101;
                        DMControl <= 'b00;
                        WriteDst <= 'b00;
                    end*/
                    MTHI: begin
                        RegDst <= 1;
                        Branch <= 0;
                        MemRead <= 0;
                        MemtoReg <= 1;
                        MemWrite <= 0;
                        ALUSrc2 <= 0;
                        ALUSrc1 <= 0;
                        RegWrite <= 1;   
                        SignExt <= 0;   // don't care
                        JumpMux = 'b00;
                        CondMov <= 0;
                        ALUControl <= 'b001010;
                        DMControl <= 'b00;
                        WriteDst <= 'b00;
                    end
                    MTLO: begin
                        RegDst <= 1;
                        Branch <= 0;
                        MemRead <= 0;
                        MemtoReg <= 1;
                        MemWrite <= 0;
                        ALUSrc2 <= 0;
                        ALUSrc1 <= 0;
                        RegWrite <= 1;   
                        SignExt <= 0;   // don't care
                        JumpMux = 'b00;
                        CondMov <= 0;
                        ALUControl <= 'b001011;
                        DMControl <= 'b00;
                        WriteDst <= 'b00;
                    end
                    MFHI: begin
                        RegDst <= 1;
                        Branch <= 0;
                        MemRead <= 0;
                        MemtoReg <= 1;
                        MemWrite <= 0;
                        ALUSrc2 <= 0;
                        ALUSrc1 <= 0;
                        RegWrite <= 1;   
                        SignExt <= 0;   // don't care
                        JumpMux = 'b00;
                        CondMov <= 0;
                        ALUControl <= 'b001100;
                        DMControl <= 'b00;
                        WriteDst <= 'b00;
                    end
                    MFLO: begin
                        RegDst <= 1;
                        Branch <= 0;
                        MemRead <= 0;
                        MemtoReg <= 1;
                        MemWrite <= 0;
                        ALUSrc2 <= 0;
                        ALUSrc1 <= 0;
                        RegWrite <= 1;   
                        SignExt <= 0;   // don't care
                        JumpMux = 'b00;
                        CondMov <= 0;
                        ALUControl <= 'b001101;
                        DMControl <= 'b00;
                        WriteDst <= 'b00;
                    end
                    /*SLL: begin
                        RegDst <= 1;
                        Branch <= 0;
                        MemRead <= 0;
                        MemtoReg <= 1;
                        MemWrite <= 0;
                        ALUSrc2 <= 0;
                        ALUSrc1 <= 1;   // shift amount
                        RegWrite <= 1;   
                        SignExt <= 0;   // don't care
                        JumpMux = 'b00;
                        CondMov <= 0;
                        ALUControl <= 'b000011;        // SLL CONTROL SIGNAL
                        DMControl <= 'b00;
                        WriteDst <= 'b00;
                    end
                    ROTR_SRL: begin
                        if(InstructionBit_21 == 'b0) begin        // means instruction is SRL
                            RegDst <= 1;
                            Branch <= 0;
                            MemRead <= 0;
                            MemtoReg <= 1;
                            MemWrite <= 0;
                            ALUSrc2 <= 0;
                            ALUSrc1 <= 1;   // shift amount
                            RegWrite <= 1;   
                            SignExt <= 0;   // don't care
                            JumpMux = 'b00;
                            CondMov <= 0;
                            ALUControl <= 'b000100;        // SRL CONTROL SIGNAL
                            DMControl <= 'b00;
                            WriteDst <= 'b00;
                        end
                        else if(InstructionBit_21 == 'b1) begin    // means instruction is ROTR
                            RegDst <= 1;
                            Branch <= 0;
                            MemRead <= 0;
                            MemtoReg <= 1;
                            MemWrite <= 0;
                            ALUSrc2 <= 0;
                            ALUSrc1 <= 1;   // shift amount
                            RegWrite <= 1;   
                            SignExt <= 0;   // don't care
                            JumpMux = 'b00;
                            CondMov <= 0;
                            ALUControl <= 'b011000;        // ROTR CONTROL SIGNAL     
                            DMControl <= 'b00;
                            WriteDst <= 'b00;
                        end
                    end
                    SLLV: begin
                        RegDst <= 1;
                        Branch <= 0;
                        MemRead <= 0;
                        MemtoReg <= 1;
                        MemWrite <= 0;
                        ALUSrc2 <= 0;
                        ALUSrc1 <= 0;
                        RegWrite <= 1;   
                        SignExt <= 0;   // don't care
                        JumpMux = 'b00;
                        CondMov <= 0;
                        ALUControl <= 'b000011;     // SLLV CONTROL SIGNAL
                        DMControl <= 'b00;
                        WriteDst <= 'b00;
                    end
                    ROTRV_SRLV: begin
                        if(InstructionBit_6 == 'b0) begin    // means the instruction is SRLV
                            RegDst <= 1;
                            Branch <= 0;
                            MemRead <= 0;
                            MemtoReg <= 1;
                            MemWrite <= 0;
                            ALUSrc2 <= 0;
                            ALUSrc1 <= 0;
                            RegWrite <= 1;   
                            SignExt <= 0;   // don't care
                            JumpMux = 'b00;
                            CondMov <= 0;
                            ALUControl<= 'b000100;        // SRLV CONTROL SIGNAL
                            DMControl <= 'b00;
                            WriteDst <= 'b00;
                        end
                        else if(InstructionBit_6 == 'b1) begin    // means the instruction is ROTRV
                            RegDst <= 1;
                            Branch <= 0;
                            MemRead <= 0;
                            MemtoReg <= 1;
                            MemWrite <= 0;
                            ALUSrc2 <= 0;
                            ALUSrc1 <= 0;
                            RegWrite <= 1;   
                            SignExt <= 0;   // don't care
                            JumpMux = 'b00;
                            CondMov <= 0;
                            ALUControl <= 'b011000;        // ROTRV CONTROL SIGNAL
                            DMControl <= 'b00;
                            WriteDst <= 'b00;
                        end
                    end
                    SLT: begin
                        RegDst <= 1;
                        Branch <= 0;
                        MemRead <= 0;
                        MemtoReg <= 1;
                        MemWrite <= 0;
                        ALUSrc2 <= 0;
                        ALUSrc1 <= 0;
                        RegWrite <= 1;   
                        SignExt <= 0;   // don't care
                        JumpMux = 'b00;
                        CondMov <= 0;
                        ALUControl <= 'b000111;
                        DMControl <= 'b00;
                        WriteDst <= 'b00;
                    end
                    MOVN: begin
                        RegDst <= 1;
                        Branch <= 0;
                        MemRead <= 0;
                        MemtoReg <= 1;
                        MemWrite <= 0;
                        ALUSrc2 <= 0;
                        ALUSrc1 <= 0;
                        RegWrite <= 1;   
                        SignExt <= 0;   // don't care
                        JumpMux = 'b00;
                        CondMov <= 1;
                        ALUControl <= 'b011001;     // MOVN CONTROL SIGNAL
                        DMControl <= 'b00;
                        WriteDst <= 'b00;
                    end
                    MOVZ: begin
                        RegDst <= 1;
                        Branch <= 0;
                        MemRead <= 0;
                        MemtoReg <= 1;
                        MemWrite <= 0;
                        ALUSrc2 <= 0;
                        ALUSrc1 <= 0;
                        RegWrite <= 1;   
                        SignExt <= 0;   // don't care
                        JumpMux = 'b00;
                        CondMov <= 1;
                        ALUControl <= 'b011010;        // MOVZ CONTROL SIGNAL
                        DMControl <= 'b00;
                        WriteDst <= 'b00;
                    end
                    SRA: begin
                        RegDst <= 1;
                       Branch <= 0;
                        MemRead <= 0;
                        MemtoReg <= 1;
                        MemWrite <= 0;
                        ALUSrc2 <= 0;
                        ALUSrc1 <= 1;   // shift amount
                        RegWrite <= 1;   
                        SignExt <= 0;   // don't care
                        //JumpMux = 'b00;
                        CondMov <= 0;
                        ALUControl <= 'b011011;        // SRA CONTROL SIGNAL
                        DMControl <= 'b00;
                        WriteDst <= 'b00;
                    end
                    SRAV: begin
                        RegDst <= 1;
                        Branch <= 0;
                        MemRead <= 0;
                        MemtoReg <= 1;
                        MemWrite <= 0;
                        ALUSrc2 <= 0;
                        ALUSrc1 <= 0;   
                        RegWrite <= 1;   
                        SignExt <= 0;   // don't care
                        JumpMux = 'b00;
                        CondMov <= 0;
                        ALUControl <= 'b011011;        // SRAV CONTROL SIGNAL
                        DMControl <= 'b00;
                        WriteDst <= 'b00;
                    end
                    SLTU: begin
                        RegDst <= 1;
                        Branch <= 0;
                        MemRead <= 0;
                        MemtoReg <= 1;
                        MemWrite <= 0;
                        ALUSrc2 <= 0;
                        ALUSrc1 <= 0;
                        RegWrite <= 1;   
                        SignExt <= 0;   // don't care
                        JumpMux = 'b00;
                        CondMov <= 0;
                        ALUControl <= 'b011100;        // SLTU CONTROL SIGNAL
                        DMControl <= 'b00;
                        WriteDst <= 'b00;
                    end*/

                    JR: begin
                        RegDst <= 0;    // don't care   
                        Branch <= 0;    // don't care
                        MemRead <= 0;   // don't care
                        MemtoReg <= 0;  // don't care
                        MemWrite <= 0;
                        ALUSrc2 <= 0;  
                        ALUSrc1 <= 0;
                        RegWrite <= 0;
                        SignExt <= 1;   // don't care
                        JumpMux <= 'b01;
                        CondMov <= 0;
                        ALUControl <= 'b000000;  // don't care
                        DMControl <= 'b00;     // don't care
                        WriteDst <= 'b00;       // don't care 
                    // we need R[rs] to get to PC, using a mux

                    default begin       // AND instruction signals
                        RegDst <= 1;
                        Branch <= 0;
                        MemRead <= 0;
                        MemtoReg <= 1;
                        MemWrite <= 0;
                        ALUSrc2 <= 0;
                        ALUSrc1 <= 0;
                        RegWrite <= 1;   
                        SignExt <= 0;   // don't care
                        JumpMux = 'b00;
                        CondMov <= 0;
                        ALUControl <= 'b000000;
                        DMControl <= 'b00;
                    end
            endcase
        	end  
  
        // Load functions (differences handled in DMControl)
        	LW: begin
        		RegDst <= 0;
        		Branch <= 0;
        		MemRead <= 1;
        		MemtoReg <= 0;
        		MemWrite <= 0;
        		ALUSrc2 <= 1;  // using offset value (immExt)
                ALUSrc1 <= 0;
        		RegWrite <= 1;
        		SignExt <= 1;
        		JumpMux = 'b00;
                CondMov <= 0;
                ALUControl <= 'b000010;
                DMControl <= 'b00;
                WriteDst <= 'b00;
        	end
        	LB: begin 	
        		RegDst <= 0;
                Branch <= 0;
                MemRead <= 1;
                MemtoReg <= 0;
                MemWrite <= 0;
                ALUSrc2 <= 1;  // using offset value (immExt)
                ALUSrc1 <= 0;
                RegWrite <= 1;
                SignExt <= 1;
                JumpMux = 'b00;
                CondMov <= 0;
                ALUControl <= 'b000010;
                DMControl <= 'b10;  // byte-mode
                WriteDst <= 'b00;
        	end
        	LH: begin 	
        		RegDst <= 0;
                Branch <= 0;
                MemRead <= 1;
                MemtoReg <= 0;
                MemWrite <= 0;
                ALUSrc2 <= 1;  // using offset value (immExt)
                ALUSrc1 <= 0;
                RegWrite <= 1;
                SignExt <= 1;
                JumpMux = 'b00;
                CondMov <= 0;
                ALUControl <= 'b000010;
                DMControl <= 'b01;  // half-word mode
                WriteDst <= 'b00;
        	end
        	LUI: begin
                RegDst <= 0;
                Branch <= 0;
                MemRead <= 1;
                MemtoReg <= 0;  // WriteData from ALUResult
                MemWrite <= 0;
                ALUSrc2 <= 1;  // using offset value (immExt)
                ALUSrc1 <= 0;
                RegWrite <= 1;
                SignExt <= 1;   // don't care
                JumpMux = 'b00;
                CondMov <= 0;
                ALUControl <= 'b100000;  // must shift left by 16 and cocatenate 16 0's to the right side
                DMControl <= 'b00; // don't care
                WriteDst <= 'b00;
        	end
        // Store Functions (diferences handled in DMControl)	
        	SW: begin
                RegDst <= 0;
                Branch <= 0;
                MemRead <= 0;
                MemtoReg <= 0;  // WriteData from ALUResult
                MemWrite <= 0;
                ALUSrc2 <= 1;  // using offset value (immExt)
                ALUSrc1 <= 0;
                RegWrite <= 0;
                SignExt <= 1;
                JumpMux = 'b00;
                CondMov <= 0;
                ALUControl <= 'b000010;
                DMControl <= 'b00;
                WriteDst <= 'b00;
        	end
        	SB: begin
                RegDst <= 0;
                Branch <= 0;
                MemRead <= 0;
                MemtoReg <= 0;  // WriteData from ALUResult
                MemWrite <= 0;
                ALUSrc2 <= 1;  // using offset value (immExt)
                ALUSrc1 <= 0;
                RegWrite <= 0;
                SignExt <= 1;
                JumpMux = 'b00;
                CondMov <= 0;
                ALUControl <= 'b000010;
                DMControl <= 'b10;  // byte-mode
                WriteDst <= 'b00;
        	end
        	SH: begin
        		RegDst <= 0;
                Branch <= 0;
                MemRead <= 0;
                MemtoReg <= 0;  // WriteData from ALUResult
                MemWrite <= 0;
                ALUSrc2 <= 1;  // using offset value (immExt)
                ALUSrc1 <= 0;
                RegWrite <= 0;
                SignExt <= 1;
                JumpMux = 'b00;
                CondMov <= 0;
                ALUControl <= 'b000010;
                DMControl <= 'b01;  // half-word mode
                WriteDst <= 'b00;
        	end
        // Branch instructions 
        	BEQ: begin
                RegDst <= 0;    // don't care
                Branch <= 1;
                MemRead <= 0;
                MemtoReg <= 0;  // don't care
                MemWrite <= 0;
                ALUSrc2 <= 0;  
                ALUSrc1 <= 0;
                RegWrite <= 0;
                SignExt <= 1;
                JumpMux = 'b00;
                CondMov <= 0;
                ALUControl <= 'b010000;
                DMControl <= 'b00;
                WriteDst <= 'b00;
        	end
        	BNE: begin
                RegDst <= 0;    // don't care
                Branch <= 1;
                MemRead <= 0;
                MemtoReg <= 0;  // don't care
                MemWrite <= 0;
                ALUSrc2 <= 0;  
                ALUSrc1 <= 0;
                RegWrite <= 0;
                SignExt <= 1;
                JumpMux = 'b00;
                CondMov <= 0;
                ALUControl <= 'b010101;
                DMControl <= 'b00;
                WriteDst <= 'b00;
        	end
        	BGTZ: begin
        		RegDst <= 0;    // don't care
                Branch <= 1;
                MemRead <= 0;
                MemtoReg <= 0;  // don't care
                MemWrite <= 0;
                ALUSrc2 <= 0;  
                ALUSrc1 <= 0;
                RegWrite <= 0;
                SignExt <= 1;
                JumpMux = 'b00;
                CondMov <= 0;
                ALUControl <= 'b010001;
                DMControl <= 'b00;
                WriteDst <= 'b00;
        	end
        	BLEZ: begin
        		RegDst <= 0;    // don't care
                Branch <= 1;
                MemRead <= 0;
                MemtoReg <= 0;  // don't care
                MemWrite <= 0;
                ALUSrc2 <= 0;  
                ALUSrc1 <= 0;
                RegWrite <= 0;
                SignExt <= 1;
                JumpMux = 'b00;
                CondMov <= 0;
                ALUControl <= 'b010011;
                DMControl <= 'b00;
                WriteDst <= 'b00;
        	end
        	BLTZ_BGEZ: begin
        		RegDst <= 0;    // don't care
                Branch <= 1;
                MemRead <= 0;
                MemtoReg <= 0;  // don't care
                MemWrite <= 0;
                ALUSrc2 <= 0;  
                ALUSrc1 <= 0;
                RegWrite <= 0;
                SignExt <= 1;
                JumpMux = 'b00;
                CondMov <= 0;
                DMControl <= 'b00;
                WriteDst <= 'b00;

                if(rt <= 'b00001) // BGEZ
                ALUControl <= 'b010000;
                else              // BLTZ
                ALUControl <= 'b010100;
        	end
        // jump functions
        	J: begin
                RegDst <= 0;    // don't care   
                Branch <= 0;    // don't care
                MemRead <= 0;   // don't care
                MemtoReg <= 0;  // don't care
                MemWrite <= 0;
                ALUSrc2 <= 0;  
                ALUSrc1 <= 0;
                RegWrite <= 0;
                SignExt <= 1;   // don't care
                JumpMux <= 'b10;
                CondMov <= 0;
                ALUControl <= 'b000000;  // don't care
                DMControl <= 'b00;     // don't care
                WriteDst <= 'b00;       // don't care
        	end
        	JAL: begin
                RegDst <= 0;    // don't care   
                Branch <= 0;    // don't care
                MemRead <= 0;   // don't care
                MemtoReg <= 0;  // don't care
                MemWrite <= 0;
                ALUSrc2 <= 0;  
                ALUSrc1 <= 0;
                RegWrite <= 0;
                SignExt <= 1;   // don't care
                JumpMux <= 'b10;
                CondMov <= 0;
                ALUControl <= 'b000000;  // don't care
                DMControl <= 'b00;
                WriteDst <= 'b01;   // uses $31
        	end

        	// Immediate functions
        	ADDI: begin
                RegDst <= 0;
                Branch <= 0;
                MemRead <= 0;   // don't care
                MemtoReg <= 1;
                MemWrite <= 0;
                ALUSrc2 <= 1;    // uses immediate value (immExt)
                ALUSrc1 <= 0;
                RegWrite <= 1;   
                SignExt <= 1;   
                JumpMux = 'b00;
                CondMov <= 0;    
                ALUControl <= 'b000010;
                DMControl <= 'b00;
                WriteDst <= 'b00;
        	end

        /*	ADDIU: begin
                RegDst <= 0;
                Branch <= 0;
                MemRead <= 0;   // don't care
                MemtoReg <= 1;
                MemWrite <= 0;
                ALUSrc2 <= 1;    // uses immediate value (immExt)
                ALUSrc1 <= 0;
                RegWrite <= 1;   
                SignExt <= 1;   // unsigned   
                JumpMux = 'b00;
                CondMov <= 0;    
                ALUControl <= 'b011111;
                DMControl <= 'b00;
                WriteDst <= 'b00;
        	end

        	ANDI: begin
        		RegDst <= 0;
                Branch <= 0;
                MemRead <= 0;   // don't care
                MemtoReg <= 1;
                MemWrite <= 0;
                ALUSrc2 <= 1;    // uses immediate value (immExt)
                ALUSrc1 <= 0;
                RegWrite <= 1;   
                SignExt <= 1;   
                JumpMux = 'b00;
                CondMov <= 0;    
                ALUControl <= 'b000000;
                DMControl <= 'b00;
                WriteDst <= 'b00;
        	end

        	ORI: begin
        		RegDst <= 0;
                Branch <= 0;
                MemRead <= 0;   // don't care
                MemtoReg <= 1;
                MemWrite <= 0;
                ALUSrc2 <= 1;    // uses immediate value (immExt)
                ALUSrc1 <= 0;
                RegWrite <= 1;   
                SignExt <= 0;   // 16bit immediate is 0 extended   
                JumpMux = 'b00;
                CondMov <= 0;    
                ALUControl <= 'b000001;
                DMControl <= 'b00;
                WriteDst <= 'b00;
                end

        	XORI: begin
        		RegDst <= 0;
                Branch <= 0;
                MemRead <= 0;   // don't care
                MemtoReg <= 1;
                MemWrite <= 0;
                ALUSrc2 <= 1;    // uses immediate value (immExt)
                ALUSrc1 <= 0;
                RegWrite <= 1;   
                SignExt <= 0;   // 16bit immediate is 0 extended   
                JumpMux = 'b00;
                CondMov <= 0;    
                ALUControl <= 'b000101;
                DMControl <= 'b00;
                WriteDst <= 'b00;
        	end

        	SLTI: begin
        		RegDst <= 0;
                Branch <= 0;
                MemRead <= 0;   // don't care
                MemtoReg <= 1;
                MemWrite <= 0;
                ALUSrc2 <= 1;    // uses immediate value (immExt)
                ALUSrc1 <= 0;
                RegWrite <= 1;   
                SignExt <= 1;   
                JumpMux = 'b00;
                CondMov <= 0;    
                ALUControl <= 'b00111;
                DMControl <= 'b00;
                WriteDst <= 'b00;
        	end

            // Multiply and Add/Sub (difference determined in ALU Control)
            MADD_SUB_MUL: begin
                RegDst <= 1;    // don't care
                Branch <= 0;
                MemRead <= 0; 
                MemtoReg <= 0;  // don't care
                MemWrite <= 0;
                ALUSrc2 <= 0;
                ALUSrc1 <= 0;
                RegWrite <= 0;   
                SignExt <= 0;   // don't care   
                JumpMux = 'b00;
                CondMov <= 0;
                DMControl <= 'b00;
                WriteDst <= 'b00; 

                case(Funct) 
                    MADD: begin
                        ALUControl <= 'b001110;
                    end
                    MSUB: begin
                        ALUControl <= 'b001111;
                    end
                    MUL: begin
                        ALUControl <= 'b001001;
                        RegWrite <= 1;
                    end
                    default begin
                        ALUControl <= 'b001110;
                        end
                endcase   
            end
                        
            SLTIU: begin
                RegDst <= 1;    // 0 or 1 ?
                Branch <= 0;
                MemRead <= 0;  
                MemtoReg <= 1;
                MemWrite <= 0;
                ALUSrc2 <= 1;    // use immediate value
                ALUSrc1 <= 0;
                RegWrite <= 1;   
                SignExt <= 1; 
                JumpMux = 'b00;
                CondMov <= 0;
                ALUControl <= 'b011100; // SLTU control signal
                DMControl <= 'b00;
                WriteDst <= 'b00;

            end
            
            SEB_SEH: begin
                if(InstructionBit_9 == 'b0) begin    // means instruction is SEB
                    RegDst <= 1;
                    Branch <= 0;
                    MemRead <= 0;
                    MemtoReg <= 1;
                    MemWrite <= 0;
                    ALUSrc2 <= 0;
                    ALUSrc1 <= 0;
                    RegWrite <= 1;   
                    SignExt <= 0;   // don't care
                    JumpMux = 'b00;
                    CondMov <= 0;
                    ALUControl <= 'b010110;                    // SEB control signal
                    DMControl <= 'b00;
                    WriteDst <= 'b00;
                end
                else if(InstructionBit_9 == 'b1) begin    // means instruction is SEH
                    RegDst <= 1;
                    Branch <= 0;
                    MemRead <= 0;
                    MemtoReg <= 1;
                    MemWrite <= 0;
                    ALUSrc2 <= 0;
                    ALUSrc1 <= 0;
                    RegWrite <= 1;   
                    SignExt <= 0;   // don't care
                    JumpMux = 'b00;
                    CondMov <= 0;
                    ALUControl <= 'b010111;                    // SEH control SIGNAL
                    DMControl <= 'b00;
                    WriteDst <= 'b00;
                end
            end*/

            default: begin // AND 
                RegDst <= 1;
                Branch <= 0;
                MemRead <= 0;
                MemtoReg <= 1;
                MemWrite <= 0;
                ALUSrc2 <= 0;
                ALUSrc1 <= 0;
                RegWrite <= 1;   
                SignExt <= 0;   // don't care
                JumpMux = 'b00;
                CondMov <= 0;
                ALUControl <= 'b000000;
                DMControl <= 'b00;
                WriteDst <= 'b00;
            end
        endcase
end
endmodule


