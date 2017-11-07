
`timescale 1ns / 1ps

/*
Percent Effort:
	Aneesa Judd - 33 %
	Victor Reyes - 33 %
	Barak Hassan - 33 % 
*/

module CPU(Clk, reset, PCResult, EX_ALUResult, Hi, Lo, WB_ALUResult, WB_MemtoRegMuxResult);

	// CPU Input and Output declaration
	input Clk, reset;
	output PCResult;		
	output EX_ALUResult, WB_ALUResult, WB_MemtoRegMuxResult;
	output [31:0] Hi, Lo;
   
	/* Instruction fetch stage */
    wire [31:0] PCAddress;
    wire [31:0] PCSrc;	// source wire for Program Counter, comes from JumpMux
    wire [31:0] IF_Instruction;
    wire [31:0] PCResult;
	wire [31:0] PCAddResult;
	wire [63:0] ALUResult_64bit;
	wire [31:0] Hi, Lo;
	
	ProgramCounter ProgramCounter_1(PCSrc, PCResult, reset, Clk);
    InstructionMemory InstructionMemory_1(PCResult, IF_Instruction); 
    PCAdder PCAdder_1(PCResult, PCAddResult);
	
	/* IFID Pipeline Register */
	wire [31:0] ID_Instruction;
	wire [31:0] ID_PCAddResult;
	IFID_reg IFID_RegFile(Clk, PCAddResult, IF_Instruction, ID_PCAddResult, ID_Instruction );
	
	/* Instruction decode stage */
	wire [4:0] ID_rs, ID_rt, ID_rd;
	wire [15:0] ID_imm;
	wire [5:0] Function, Op;
	wire [31:0] ID_sa, ID_JumpAddress;
	wire InstructionBit_6, InstructionBit_9, InstructionBit_21;
	assign Op = ID_Instruction[31:26];
    assign ID_rs = ID_Instruction[25:21];
    assign ID_rt = ID_Instruction[20:16];
    assign ID_rd = ID_Instruction[15:11];
    assign ID_imm = ID_Instruction[15:0];
    assign Function = ID_Instruction[5:0];
    assign ID_sa = {27'b0, ID_Instruction[10:6]};
    //assign ID_JumpAddress = ID_Instruction[25:0]:
    assign InstructionBit_6 = ID_Instruction[6];
    assign InstructionBit_9 = ID_Instruction[9];
    assign InstructionBit_21 = ID_Instruction[21];

    wire [27:0] ID_JumpIntrmdt;
    // Jump mechanism
    ShiftLeft26Bit JumpShiftLeft(ID_Instruction[25:0], ID_JumpIntrmdt);
    Concatenate ID_Concatenate(ID_JumpIntrmdt, ID_PCAddResult, ID_JumpAddress);
	
	wire ID_RegDst, ID_ALUSrc2, ID_RegWrite, ID_SignExt, ID_CondMov, ID_ALUSrc1;
	wire ID_MemtoReg, ID_MemWrite, ID_MemRead, ID_Branch;
	wire [1:0] ID_WriteDst, ID_JumpMux, ID_DMControl;
	wire [5:0] ID_ALUControl;
	
	Control MainControl(
		// input data
        Op, Function, InstructionBit_6, InstructionBit_9, InstructionBit_21, ID_rt, 
      
       // output signals
       ID_Branch, ID_MemRead, ID_MemtoReg, ID_MemWrite,
       ID_RegDst, ID_ALUSrc2, ID_RegWrite, ID_SignExt, ID_CondMov, ID_ALUSrc1, 
       ID_ALUControl, ID_DMControl, ID_WriteDst, ID_JumpMux );
	
	wire [31:0] ID_ReadData1, ID_ReadData2, WB_ALUResult, WB_MemtoRegMuxResult; 
	wire [31:0] WriteData;	
	wire [4:0] WB_WriteRegister;
	wire WB_RegWriteResult;
													                                                               // $31
	 Mux32Bit4To1 WriteDataMux(WriteData, WB_MemtoRegMuxResult, 'b11111, WB_MemtoRegMuxResult, ID_PCAddResult, ID_WriteDst);
	
	
	RegisterFile RegisterFile_1(
    	ID_rs,
    	ID_rt,
    	WB_WriteRegister,
    	WriteData,		
    	WB_RegWriteResult,		
    	Clk,
    	ID_ReadData1,
    	ID_ReadData2
    	);
	
	wire [31:0] ID_immExt;
	
	SignExtension SignExtension_1(ID_imm, ID_immExt, ID_SignExt);
	
	/* IDEX Pipeline Register */
	wire [31:0] EX_ReadData1, EX_ReadData2, EX_immExt, EX_PCAddResult, EX_JumpAddress;
	wire [4:0] EX_rt, EX_rd;
	wire [31:0] EX_sa;

	wire EX_RegWrite, EX_CondMov, EX_RegDst, EX_ALUSrc1, EX_ALUSrc2;
	wire EX_MemtoReg, EX_MemWrite, EX_MemRead, EX_Branch;
	wire [1:0] EX_WriteDst, EX_JumpMux, EX_DMControl;
	wire [5:0] EX_ALUControl;
	
	IDEX_reg IDEX_RegFile(
		Clk,
		ID_RegWrite,
		ID_CondMov,
		ID_MemtoReg,
		ID_MemWrite,
		ID_MemRead,
		ID_RegDst,
		ID_ALUControl,
		ID_ALUSrc1,
		ID_ALUSrc2,
		ID_Branch,
		ID_WriteDst,
		ID_JumpMux,
		ID_DMControl,

		ID_PCAddResult,
		ID_JumpAddress,
		ID_ReadData1,
		ID_ReadData2,
		ID_immExt,
		ID_rt,
		ID_rd,
		ID_sa,
			
		EX_RegWrite,
		EX_CondMov,
		EX_MemtoReg,
		EX_MemWrite,
		EX_MemRead,
		EX_RegDst,
		EX_ALUControl,
		EX_ALUSrc1,
		EX_ALUSrc2,
		EX_Branch,
		EX_WriteDst,
		EX_JumpMux,
		EX_DMControl,
					
		EX_PCAddResult,
		EX_JumpAddress,
		EX_ReadData1,
		EX_ReadData2,
		EX_immExt,
		EX_rt,
		EX_rd,
		EX_sa );
	
	/* Execution Stage */
	wire [31:0] ALUSrcMuxResult_1, ALUSrcMuxResult_2;
	Mux32Bit2To1 ALUSrcMux_1(ALUSrcMuxResult_1, EX_ReadData1, EX_sa, EX_ALUSrc1);
    Mux32Bit2To1 ALUSrcMux_2(ALUSrcMuxResult_2, EX_ReadData2, EX_immExt, EX_ALUSrc2);
	
	wire [31:0] EX_ALUResult;
	wire EX_ZeroFlag;
	ALU32Bit ALU(EX_ALUControl, ALUSrcMuxResult_1, ALUSrcMuxResult_2, EX_ALUResult, EX_ZeroFlag, Hi, Lo, ALUResult_64bit);
	assign Hi = ALUResult_64bit[63:32];
	assign Lo = ALUResult_64bit[31:0];
	wire [4:0] EX_WriteRegister;
	Mux5Bit2To1 RegDstMux(EX_WriteRegister, EX_rt, EX_rd, EX_RegDst);

	// new
	wire[31:0] EX_ShiftLeftResult;
	wire[31:0] EX_AdderResult;
	ShiftLeft32Bit EX_ShiftLeft(EX_immExt, EX_ShiftLeftResult);
	Adder32Bit EX_Adder(EX_PCAddResult, EX_ShiftLeftResult, EX_AdderResult);

	
	/* EXMEM Pipeline Register */
	wire MEM_RegWrite, MEM_CondMov, MEM_ZeroFlag, MEM_MemtoReg, MEM_MemWrite, MEM_MemRead, MEM_Branch;
	wire [1:0] MEM_JumpMux, MEM_DMControl;
	wire [31:0] MEM_ALUResult, MEM_AdderResult, MEM_JumpAddress, MEM_PCAddResult, MEM_ReadData1, MEM_ReadData2;
	wire [4:0] MEM_WriteRegister;
	
	EXMEM_reg EXMEM_RegFile(
		Clk,				
		EX_RegWrite,
		EX_CondMov,
		EX_MemtoReg,
		EX_MemWrite,
		EX_MemRead,
		EX_JumpMux, 	// new
		EX_DMControl,	// new
		EX_Branch,
		
        EX_ZeroFlag,
		EX_AdderResult,	// new
		EX_ALUResult,
		EX_WriteRegister, // new
		EX_JumpAddress,	// new
		EX_PCAddResult,	// new
		EX_ReadData1,  	// new
		EX_ReadData2,


		MEM_RegWrite,
		MEM_CondMov,
		MEM_MemtoReg,
		MEM_MemWrite,
		MEM_MemRead,
		MEM_JumpMux,
		MEM_DMControl,
		MEM_Branch,

        MEM_ZeroFlag,
		MEM_AdderResult,
		MEM_ALUResult,
		MEM_WriteRegister,
		MEM_JumpAddress,
		MEM_PCAddResult,
		MEM_ReadData1,
		MEM_ReadData2 );
	
	/* Memory Stage */
	wire MEM_JumpMuxSrc;
	wire [31:0] MEM_AdderMuxResult;
	wire [31:0] MEM_DMResult;

	DataMemory DM(MEM_ALUResult, MEM_ReadData2, Clk, MEM_MemWrite, MEM_MemRead, MEM_DMControl, MEM_DMResult);

	AndModule AndBranchZeroResult(MEM_ZeroFlag, MEM_Branch, MEM_JumpMuxSrc);
	Mux32Bit2To1 AdderResultMux(MEM_AdderMuxResult, MEM_PCAddResult, MEM_AdderResult, MEM_JumpMuxSrc);
	Mux32Bit4To1 JumpMux1(PCSrc, MEM_AdderMuxResult, MEM_ReadData1, MEM_JumpAddress, MEM_AdderMuxResult, MEM_JumpMux);

	
	/* MEMWB Pipeline Register */
	wire WB_RegWrite, WB_CondMov, WB_MemtoReg, WB_ZeroFlag;
	wire [31:0] WB_DMResult;
	
	MEMWB_reg MEMWB_RegFile(
		Clk,
		MEM_RegWrite,
	    MEM_CondMov,
	    MEM_MemtoReg,
	    
		MEM_ZeroFlag,
		MEM_ALUResult,
		MEM_WriteRegister,
		MEM_DMResult,

		WB_RegWrite,
	    WB_CondMov,
	    WB_MemtoReg,

        WB_ZeroFlag,			
		WB_ALUResult,
		WB_WriteRegister,
		WB_DMResult );
	
	/* Write Back Stage */		
	CondMov CondMovLogic(
		WB_RegWrite, 
		WB_CondMov, 
		WB_ZeroFlag, 
		WB_RegWriteResult );

	Mux32Bit2To1 WBMux(WB_MemtoRegMuxResult, WB_DMResult, WB_ALUResult, WB_MemtoReg);
endmodule