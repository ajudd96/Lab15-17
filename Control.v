`timescale 1ns / 1ps

module Control(
               // input regs
               Op, Funct, /*InstructionBit_6, InstructionBit_9, InstructionBit_21,*/  rt, 
              Branch, MemRead, MemtoReg, MemWrite,
              // output signals
                RegDst, ALUSrc2, RegWrite, SignExt, Jump, /*CondMov, ALUSrc1,*/
               Link, Link31, WriteDst, 
               ALUControl, DMControl );    // output

	input [5:0] Op; // control bits for ALU operation
    input [5:0] Funct;  // to determine ALUControl for r-type operations
    // To help differentiate instuctions that have the same OpCode and functCode
        /*input InstructionBit_6;         // to differentiate between ROTRV or SRLV
        input InstructionBit_9;         // to differentiate between SEB and SEH
        input InstructionBit_21;        // to differentiate between ROTR and SRL*/
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
    //output reg ALUSrc1;     // chooses between R[rs] (ALUSrc ==0) and sa(shift amount)(ALUSrc == 1) for ALU input A
	output reg RegWrite;	// RegWrite == 1 if r-type or lw instruction and 0 if sw or branch 
	output reg SignExt;		// SignExt == 1 if Sign Extend requires sign extension, 0 for 0 extension (unsigned numbers)
	output reg Jump;		// Jump == 1 if a jump instruction
	output reg Link;        // Link == 1 if a link instruction (jr, jal). Select bit for a mux between PC + 4 and Data Memory output
    output reg Link31;      // Link31 == 1 if jump and link (jal). Together wih Link (And module)
    //output reg CondMov;   // CondMov == 1 if movn or movz. This bit is ANDed with ALU ZeroFlag
                            // and ORed with RegWrite signal
    output reg [1:0] WriteDst;  // Controls 4 to 1 mux to Write Data port of regfile
        // 'WriteDst' value | Source
        // ==========================
        // 00   | Output of MemtoReg mux
        // 01   | register $31
        // 10   | unused
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

output reg [2:0] DMControl; 
        // Op   | 'DMControl' value
        // ==========================
        // lw   | 000
        // sw   | 001
        // lb   | 010
        // sb   | 011
        // lh   | 100
        // sh   | 101 
        // n/a  | 110
        // n/a  | 111

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
          //CondMov = 'b0;
          //ALUSrc1 = 'b0;
          RegWrite = 0;  
          SignExt = 0;   
          Jump <= 0;
          DMControl <= 'b000;
          WriteDst = 'b00;
    
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
                        Jump <= 0;
                        CondMov <= 0;    
                        ALUControl <= 'b000010;
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
                           Jump <= 0;
                           CondMov <= 0;    
                           ALUControl <= 'b011111;
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
                        //Jump <= 0;
                        CondMov <= 0;
                        ALUControl <= 'b000110;
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
                        //Jump <= 0;
                        CondMov <= 0;
                        ALUControl <= 'b000000;
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
                        //Jump <= 0;
                        CondMov <= 0;
                        ALUControl <= 'b000001;
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
                        //Jump <= 0;
                        CondMov <= 0;
                        ALUControl <= 'b000101;
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
                        //Jump <= 0;
                        CondMov <= 0;
                        ALUControl <= 'b001000;
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
                        //Jump <= 0;
                        CondMov <= 0;
                        ALUControl <= 'b011110;
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
                        //Jump <= 0;
                        CondMov <= 0;
                        ALUControl <= 'b011101;
                    end*/
                    MTHI: begin
                        RegDst <= 1;
                        Branch <= 0;
                        MemRead <= 0;
                        MemtoReg <= 1;
                        MemWrite <= 0;
                        ALUSrc2 <= 0;
                        //ALUSrc1 <= 0;
                        RegWrite <= 1;   
                        SignExt <= 0;   // don't care
                        Jump <= 0;
                        CondMov <= 0;
                        ALUControl <= 'b001010;
                        DMControl <= 'b000;
                        WriteDst <= 'b00;
                    end
                    MTLO: begin
                        RegDst <= 1;
                        Branch <= 0;
                        MemRead <= 0;
                        MemtoReg <= 1;
                        MemWrite <= 0;
                        ALUSrc2 <= 0;
                        //ALUSrc1 <= 0;
                        RegWrite <= 1;   
                        SignExt <= 0;   // don't care
                        Jump <= 0;
                        CondMov <= 0;
                        ALUControl <= 'b001011;
                        DMControl <= 'b000;
                        WriteDst <= 'b00;
                    end
                    MFHI: begin
                        RegDst <= 1;
                        Branch <= 0;
                        MemRead <= 0;
                        MemtoReg <= 1;
                        MemWrite <= 0;
                        ALUSrc2 <= 0;
                        //ALUSrc1 <= 0;
                        RegWrite <= 1;   
                        SignExt <= 0;   // don't care
                        Jump <= 0;
                        CondMov <= 0;
                        ALUControl <= 'b001100;
                        DMControl <= 'b000;
                        WriteDst <= 'b00;
                    end
                    MFLO: begin
                        RegDst <= 1;
                        Branch <= 0;
                        MemRead <= 0;
                        MemtoReg <= 1;
                        MemWrite <= 0;
                        ALUSrc2 <= 0;
                        //ALUSrc1 <= 0;
                        RegWrite <= 1;   
                        SignExt <= 0;   // don't care
                        Jump <= 0;
                        CondMov <= 0;
                        ALUControl <= 'b001101;
                        DMControl <= 'b000;
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
                        //Jump <= 0;
                        CondMov <= 0;
                        ALUControl <= 'b000011;        // SLL CONTROL SIGNAL
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
                            Jump <= 0;
                            CondMov <= 0;
                            ALUControl <= 'b000100;        // SRL CONTROL SIGNAL
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
                            Jump <= 0;
                            CondMov <= 0;
                            ALUControl <= 'b011000;        // ROTR CONTROL SIGNAL     
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
                        Jump <= 0;
                        CondMov <= 0;
                        ALUControl <= 'b000011;     // SLLV CONTROL SIGNAL
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
                            Jump <= 0;
                            CondMov <= 0;
                            ALUControl<= 'b000100;        // SRLV CONTROL SIGNAL
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
                            Jump <= 0;
                            CondMov <= 0;
                            ALUControl <= 'b011000;        // ROTRV CONTROL SIGNAL
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
                        Jump <= 0;
                        CondMov <= 0;
                        ALUControl <= 'b000111;
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
                        Jump <= 0;
                        CondMov <= 1;
                        ALUControl <= 'b011001;     // MOVN CONTROL SIGNAL
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
                        Jump <= 0;
                        CondMov <= 1;
                        ALUControl <= 'b011010;        // MOVZ CONTROL SIGNAL
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
                        //Jump <= 0;
                        CondMov <= 0;
                        ALUControl <= 'b011011;        // SRA CONTROL SIGNAL
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
                        Jump <= 0;
                        CondMov <= 0;
                        ALUControl <= 'b011011;        // SRAV CONTROL SIGNAL
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
                        Jump <= 0;
                        CondMov <= 0;
                        ALUControl <= 'b011100;        // SLTU CONTROL SIGNAL
                    end*/

                    JR: begin
                        RegDst <= 0;    // don't care   
                        Branch <= 0;    // don't care
                        MemRead <= 0;   // don't care
                        MemtoReg <= 0;  // don't care
                        MemWrite <= 0;
                        ALUSrc2 <= 0;  
                        //ALUSrc1 <= 0;
                        RegWrite <= 0;
                        SignExt <= 1;   // don't care
                        Jump <= 1;
                        //CondMov <= 0;
                        ALUControl <= 'b000000;  // don't care
                        DMControl <= 'b000;     // don't care
                        WriteDst <= 'b00;       // don't care 
                    // we need R[rs] to get to PC, using a mux

                    default begin       // AND instruction signals
                        RegDst <= 1;
                        Branch <= 0;
                        MemRead <= 0;
                        MemtoReg <= 1;
                        MemWrite <= 0;
                        ALUSrc2 <= 0;
                        //ALUSrc1 <= 0;
                        RegWrite <= 1;   
                        SignExt <= 0;   // don't care
                        Jump <= 0;
                        //CondMov <= 0;
                        ALUControl <= 'b000000;
                        DMControl <= 'b000;
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
                //ALUSrc1 <= 0;
        		RegWrite <= 1;
        		SignExt <= 1;
        		Jump <= 0;
                //CondMov <= 0;
                ALUControl <= 'b000010;
                DMControl <= 'b000;
                WriteDst <= 'b00;
        	end
        	LB: begin 	
        		RegDst <= 0;
                Branch <= 0;
                MemRead <= 1;
                MemtoReg <= 0;
                MemWrite <= 0;
                ALUSrc2 <= 1;  // using offset value (immExt)
                //ALUSrc1 <= 0;
                RegWrite <= 1;
                SignExt <= 1;
                Jump <= 0;
                //CondMov <= 0;
                ALUControl <= 'b000010;
                DMControl <= 'b010;
                WriteDst <= 'b00;
        	end
        	LH: begin 	
        		RegDst <= 0;
                Branch <= 0;
                MemRead <= 1;
                MemtoReg <= 0;
                MemWrite <= 0;
                ALUSrc2 <= 1;  // using offset value (immExt)
                //ALUSrc1 <= 0;
                RegWrite <= 1;
                SignExt <= 1;
                Jump <= 0;
                //CondMov <= 0;
                ALUControl <= 'b000010;
                DMControl <= 'b100;
                WriteDst <= 'b00;
        	end
        	LUI: begin
                RegDst <= 0;
                Branch <= 0;
                MemRead <= 1;
                MemtoReg <= 0;  // WriteData from ALUResult
                MemWrite <= 0;
                ALUSrc2 <= 1;  // using offset value (immExt)
                //ALUSrc1 <= 0;
                RegWrite <= 1;
                SignExt <= 1;   // don't care
                Jump <= 0;
                //CondMov <= 0;
                ALUControl <= 'b100000;  // must shift left by 16 and cocatenate 16 0's to the right side
                DMControl <= 'b000; // don't care
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
                //ALUSrc1 <= 0;
                RegWrite <= 0;
                SignExt <= 1;
                Jump <= 0;
                //CondMov <= 0;
                ALUControl <= 'b000010;
                DMControl <= 'b001;
                WriteDst <= 'b00;
        	end
        	SB: begin
                RegDst <= 0;
                Branch <= 0;
                MemRead <= 0;
                MemtoReg <= 0;  // WriteData from ALUResult
                MemWrite <= 0;
                ALUSrc2 <= 1;  // using offset value (immExt)
                //ALUSrc1 <= 0;
                RegWrite <= 0;
                SignExt <= 1;
                Jump <= 0;
                //CondMov <= 0;
                ALUControl <= 'b000010;
                DMControl <= 'b011;
                WriteDst <= 'b00;
        	end
        	SH: begin
        		RegDst <= 0;
                Branch <= 0;
                MemRead <= 0;
                MemtoReg <= 0;  // WriteData from ALUResult
                MemWrite <= 0;
                ALUSrc2 <= 1;  // using offset value (immExt)
                //ALUSrc1 <= 0;
                RegWrite <= 0;
                SignExt <= 1;
                Jump <= 0;
                //CondMov <= 0;
                ALUControl <= 'b000010;
                DMControl <= 'b101;
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
                //ALUSrc1 <= 0;
                RegWrite <= 0;
                SignExt <= 1;
                Jump <= 0;
                //CondMov <= 0;
                ALUControl <= 'b010000;
                DMControl <= 'b000;
                WriteDst <= 'b00;
        	end
        	BNE: begin
                RegDst <= 0;    // don't care
                Branch <= 1;
                MemRead <= 0;
                MemtoReg <= 0;  // don't care
                MemWrite <= 0;
                ALUSrc2 <= 0;  
                //ALUSrc1 <= 0;
                RegWrite <= 0;
                SignExt <= 1;
                Jump <= 0;
                //CondMov <= 0;
                ALUControl <= 'b010101;
                DMControl <= 'b000;
                WriteDst <= 'b00;
        	end
        	BGTZ: begin
        		RegDst <= 0;    // don't care
                Branch <= 1;
                MemRead <= 0;
                MemtoReg <= 0;  // don't care
                MemWrite <= 0;
                ALUSrc2 <= 0;  
                //ALUSrc1 <= 0;
                RegWrite <= 0;
                SignExt <= 1;
                Jump <= 0;
                //CondMov <= 0;
                ALUControl <= 'b010001;
                DMControl <= 'b000;
                WriteDst <= 'b00;
        	end
        	BLEZ: begin
        		RegDst <= 0;    // don't care
                Branch <= 1;
                MemRead <= 0;
                MemtoReg <= 0;  // don't care
                MemWrite <= 0;
                ALUSrc2 <= 0;  
                //ALUSrc1 <= 0;
                RegWrite <= 0;
                SignExt <= 1;
                Jump <= 0;
                //CondMov <= 0;
                ALUControl <= 'b010011;
                DMControl <= 'b000;
                WriteDst <= 'b00;
        	end
        	BLTZ_BGEZ: begin
        		RegDst <= 0;    // don't care
                Branch <= 1;
                MemRead <= 0;
                MemtoReg <= 0;  // don't care
                MemWrite <= 0;
                ALUSrc2 <= 0;  
                //ALUSrc1 <= 0;
                RegWrite <= 0;
                SignExt <= 1;
                Jump <= 0;
                //CondMov <= 0;
                DMControl <= 'b000;
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
                //ALUSrc1 <= 0;
                RegWrite <= 0;
                SignExt <= 1;   // don't care
                Jump <= 1;
                //CondMov <= 0;
                ALUControl <= 'b000000;  // don't care
                DMControl <= 'b000;     // don't care
                WriteDst <= 'b00;       // don't care
        	end
        	JAL: begin
                RegDst <= 0;    // don't care   
                Branch <= 0;    // don't care
                MemRead <= 0;   // don't care
                MemtoReg <= 0;  // don't care
                MemWrite <= 0;
                ALUSrc2 <= 0;  
                //ALUSrc1 <= 0;
                RegWrite <= 0;
                SignExt <= 1;   // don't care
                Jump <= 1;
                //Link <= 1;
                //Link31 <= 1;
                //CondMov <= 0;
                ALUControl <= 'b000000;  // don't care
                DMControl <= 'b000;
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
                //ALUSrc1 <= 0;
                RegWrite <= 1;   
                SignExt <= 1;   
                Jump <= 0;
                //CondMov <= 0;    
                ALUControl <= 'b000010;
                DMControl <= 'b000;
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
                Jump <= 0;
                CondMov <= 0;    
                ALUControl <= 'b011111;
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
                Jump <= 0;
                CondMov <= 0;    
                ALUControl <= 'b000000;
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
                Jump <= 0;
                CondMov <= 0;    
                ALUControl <= 'b000001;
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
                Jump <= 0;
                CondMov <= 0;    
                ALUControl <= 'b000101;
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
                Jump <= 0;
                CondMov <= 0;    
                ALUControl <= 'b00111;
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
                Jump <= 0;
                CondMov <= 0; 

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
                Jump <= 0;
                CondMov <= 0;
                ALUControl <= 'b011100; // SLTU control signal


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
                    Jump <= 0;
                    CondMov <= 0;
                    ALUControl <= 'b010110;                    // SEB control signal
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
                    Jump <= 0;
                    CondMov <= 0;
                    ALUControl <= 'b010111;                    // SEH control SIGNAL
                end
            end*/

            default: begin // AND 
                RegDst <= 1;
                Branch <= 0;
                MemRead <= 0;
                MemtoReg <= 1;
                MemWrite <= 0;
                ALUSrc2 <= 0;
                //ALUSrc1 <= 0;
                RegWrite <= 1;   
                SignExt <= 0;   // don't care
                Jump <= 0;
                //CondMov <= 0;
                ALUControl <= 'b000000;
                DMControl <= 'b000;
                WriteDst <= 'b00;
            end
        endcase
end
endmodule


