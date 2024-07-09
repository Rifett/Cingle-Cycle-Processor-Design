module processor( input         clk, reset,
                  output [31:0] PC,
                  input  [31:0] instr,
                  output        we,
                  output [31:0] address_to_mem,
                  output [31:0] data_to_mem,
                  input  [31:0] data_from_mem
                );

    wire branchBeq, branchJal, branchJalr, regWrite, memToReg, memWrite, ALUSrc, luiImm, luiImmBranch;
    wire [3:0] ALUControl;
    wire [2:0] immControl;
    wire [31:0] resBeforeBranchTarget, res, rv1, rv2;
    wire [31:0] immOp;
    wire [31:0] luiImmToAddToPC;
    wire [31:0] secondSrc;
    wire [31:0] ALUOut;
    wire [31:0] PCPlus4;
    wire[31:0] branchTargetCandidate;
    wire [31:0] branchTarget;
    wire branchJalx;
    wire [31:0] resultCandidate, memRes;
    wire[31:0] luiImmOp;
    wire branchOutcome;
    wire [31:0] PCn;
    
    
    controlUnit controller(instr, branchBeq, branchJal, branchJalr, regWrite, memToReg, memWrite, ALUSrc, luiImm, luiImmBranch, ALUControl, immControl);
    
    GPRSet GPRs(instr[19:15], instr[24:20], instr[11:7], res, clk, regWrite, rv1, rv2);
    
    immDecode immDecoder(instr, immControl, immOp);
    
    mux beforeALU(rv2, immOp, ALUSrc, secondSrc);
    
    ALU ALUnit(rv1, secondSrc, ALUControl, ALUOut);
    
    assign address_to_mem = ALUOut;
    assign data_to_mem = rv2;
    assign we = memWrite;
    
    ALU PC4Adder (32'b100, PC, 4'b0, PCPlus4);
    
    mux immPCAdderMux (immOp, luiImmOp, luiImmBranch, luiImmToAddToPC);
    
    ALU immPCAdder(luiImmToAddToPC, PC, 4'b0, branchTargetCandidate);
    
    mux branchTargetMux(branchTargetCandidate, ALUOut, branchJalr, branchTarget);
    
    assign branchJalx = branchJal || branchJalr;
    
    mux branchJalxMux(ALUOut, PCPlus4, branchJalx, resultCandidate);
    
    mux dataMemMux(resultCandidate, data_from_mem, memToReg, memRes);
    
    luiImmAdder luiImmTransform(immOp[31:12], luiImmOp);
    
    mux almostFinalMux(memRes, luiImmOp, luiImm, resBeforeBranchTarget);
    
    mux finalMux(resBeforeBranchTarget, branchTarget, luiImmBranch, res);
    
    assign branchOutcome = (branchBeq & ALUOut[0]) || branchJalx;
    
    mux PCMux(PCPlus4, branchTarget, branchOutcome, PCn);
    
    register PCReg(PCn, clk, reset, PC);
    
    
endmodule







/*
		ALUControl:
		0000 -> +
		0001 -> -
		0010 -> AND
		0011 -> OR
		0100 -> <
		0101 -> div
		0110 -> rem
		0111 -> ==
		1000 -> <<
		1001 -> >> (unsigned)
		1010 -> >> (signed)
		
		immControl:
		{0, 0, 0} -> R-type
		{0, 0, 1} -> I-type
		{0, 1, 0} -> S-type
		{0, 1, 1} -> B-type
		{1, 0, 0} -> U-type
		{1, 0, 1} -> J-type
		{1, 1, 0} -> ???
		{1, 1, 1} -> Don't care
*/
module controlUnit ( input [31:0] instr, 
		     output reg branchBeq, branchJal, branchJalr, regWrite, memToReg, memWrite, ALUSrc, luiImm,luiImmBranch ,
		     output reg [3:0] ALUControl, 
		     output reg [2:0] immControl
		    );
	
	always @*
		casez(instr)
		32'b0000000??????????000?????0110011: //add case
			{branchBeq, branchJal, branchJalr, regWrite, memToReg, memWrite, ALUSrc, luiImm, luiImmBranch, immControl, ALUControl} = 
			{     1'b0,      1'b0,       1'b0,     1'b1,     1'b0,     1'b0,   1'b0,   1'b0,         1'b0,     3'b000,    4'b0000};
		32'b?????????????????000?????0010011: //addi case
			{branchBeq, branchJal, branchJalr, regWrite, memToReg, memWrite, ALUSrc, luiImm, luiImmBranch, immControl, ALUControl} = 
			{     1'b0,      1'b0,       1'b0,     1'b1,     1'b0,     1'b0,   1'b1,   1'b0,         1'b0,     3'b001,    4'b0000};
		32'b0000000??????????111?????0110011: //and case
			{branchBeq, branchJal, branchJalr, regWrite, memToReg, memWrite, ALUSrc, luiImm, luiImmBranch, immControl, ALUControl} = 
			{     1'b0,      1'b0,       1'b0,     1'b1,     1'b0,     1'b0,   1'b0,   1'b0,         1'b0,     3'b000,    4'b0010};
		32'b0100000??????????000?????0110011: //sub case
			{branchBeq, branchJal, branchJalr, regWrite, memToReg, memWrite, ALUSrc, luiImm, luiImmBranch, immControl, ALUControl} = 
			{     1'b0,      1'b0,       1'b0,     1'b1,     1'b0,     1'b0,   1'b0,   1'b0,         1'b0,     3'b000,    4'b0001};
		32'b0000000??????????010?????0110011: //slt case
			{branchBeq, branchJal, branchJalr, regWrite, memToReg, memWrite, ALUSrc, luiImm, luiImmBranch, immControl, ALUControl} = 
			{     1'b0,      1'b0,       1'b0,     1'b1,     1'b0,     1'b0,   1'b0,   1'b0,         1'b0,     3'b000,    4'b0100};
		32'b0000001??????????100?????0110011: //div case
			{branchBeq, branchJal, branchJalr, regWrite, memToReg, memWrite, ALUSrc, luiImm, luiImmBranch, immControl, ALUControl} = 
			{     1'b0,      1'b0,       1'b0,     1'b1,     1'b0,     1'b0,   1'b0,   1'b0,         1'b0,     3'b000,    4'b0101};
		32'b0000001??????????110?????0110011: //rem case
			{branchBeq, branchJal, branchJalr, regWrite, memToReg, memWrite, ALUSrc, luiImm, luiImmBranch, immControl, ALUControl} = 
			{     1'b0,      1'b0,       1'b0,     1'b1,     1'b0,     1'b0,   1'b0,   1'b0,         1'b0,     3'b000,    4'b0110};
		32'b?????????????????000?????1100011: // beq case
			{branchBeq, branchJal, branchJalr, regWrite, memToReg, memWrite, ALUSrc, luiImm, luiImmBranch, immControl, ALUControl} = 
			{     1'b1,      1'b0,       1'b0,     1'b0,     1'b0,     1'b0,   1'b0,   1'b0,         1'b0,     3'b011,    4'b0111};
		32'b?????????????????100?????1100011: //blt case 
			{branchBeq, branchJal, branchJalr, regWrite, memToReg, memWrite, ALUSrc, luiImm, luiImmBranch, immControl, ALUControl} = 
			{     1'b1,      1'b0,       1'b0,     1'b0,     1'b0,     1'b0,   1'b0,   1'b0,         1'b0,     3'b011,    4'b0100};
		32'b?????????????????010?????0000011: //lw case
			{branchBeq, branchJal, branchJalr, regWrite, memToReg, memWrite, ALUSrc, luiImm, luiImmBranch, immControl, ALUControl} = 
			{     1'b0,      1'b0,       1'b0,     1'b1,     1'b1,     1'b0,   1'b1,   1'b0,         1'b0,     3'b001,    4'b0000};
		32'b?????????????????010?????0100011: //sw case
			{branchBeq, branchJal, branchJalr, regWrite, memToReg, memWrite, ALUSrc, luiImm, luiImmBranch, immControl, ALUControl} = 
			{     1'b0,      1'b0,       1'b0,     1'b0,     1'b0,     1'b1,   1'b1,   1'b0,         1'b0,     3'b010,    4'b0000};
		32'b?????????????????????????0110111: //lui case 
			{branchBeq, branchJal, branchJalr, regWrite, memToReg, memWrite, ALUSrc, luiImm, luiImmBranch, immControl, ALUControl} = 
			{     1'b0,      1'b0,       1'b0,     1'b1,     1'b0,     1'b0,   1'b0,   1'b1,         1'b0,     3'b100,    4'b0000};
		32'b?????????????????????????1101111: //jal case
			{branchBeq, branchJal, branchJalr, regWrite, memToReg, memWrite, ALUSrc, luiImm, luiImmBranch, immControl, ALUControl} = 
			{     1'b0,      1'b1,       1'b0,     1'b1,     1'b0,     1'b0,   1'b0,   1'b0,         1'b0,     3'b101,    4'b0000};
		32'b?????????????????000?????1100111: //jalr case
			{branchBeq, branchJal, branchJalr, regWrite, memToReg, memWrite, ALUSrc, luiImm, luiImmBranch, immControl, ALUControl} = 
			{     1'b0,      1'b0,       1'b1,     1'b1,     1'b0,     1'b0,   1'b1,   1'b0,         1'b0,     3'b001,    4'b0000};
		32'b?????????????????????????0010111: //auipc case
			{branchBeq, branchJal, branchJalr, regWrite, memToReg, memWrite, ALUSrc, luiImm, luiImmBranch, immControl, ALUControl} = 
			{     1'b0,      1'b0,       1'b0,     1'b1,     1'b0,     1'b0,   1'b0,   1'b0,         1'b1,     3'b100,    4'b0000};
		32'b0000000??????????001?????0110011: //sll case
			{branchBeq, branchJal, branchJalr, regWrite, memToReg, memWrite, ALUSrc, luiImm, luiImmBranch, immControl, ALUControl} = 
			{     1'b0,      1'b0,       1'b0,     1'b1,     1'b0,     1'b0,   1'b0,   1'b0,         1'b0,     3'b000,    4'b1000};
		32'b0000000??????????101?????0110011: //srl case
			{branchBeq, branchJal, branchJalr, regWrite, memToReg, memWrite, ALUSrc, luiImm, luiImmBranch, immControl, ALUControl} = 
			{     1'b0,      1'b0,       1'b0,     1'b1,     1'b0,     1'b0,   1'b0,   1'b0,         1'b0,     3'b000,    4'b1001};
		32'b0100000??????????101?????0110011: //sra case
			{branchBeq, branchJal, branchJalr, regWrite, memToReg, memWrite, ALUSrc, luiImm, luiImmBranch, immControl, ALUControl} = 
			{     1'b0,      1'b0,       1'b0,     1'b1,     1'b0,     1'b0,   1'b0,   1'b0,         1'b0,     3'b000,    4'b1010};
		default: 
		; 
	endcase
endmodule

module immDecode ( input [31:0]  instr,
		   input [2:0]   immControl,
		   output reg [31:0] imm
		  );
	always @*
		casez (immControl)
		3'b000: //R-type
		imm = { 32{1'b0}};
		3'b001: //I-type
		imm = { { 21{instr[31]}}, instr[30:20]};
		3'b010: //S-type
		imm = { { 21{instr[31]}}, instr[30:25], instr[11:7]};
		3'b011: //B-type
		imm = { { 20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
		3'b100: //U-type
		imm = {instr[31:12], 12'b0};
		3'b101: //J-type
		imm = { { 12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
		default:
		;
	endcase
endmodule

module mux(input [31:0]case_0, case_1, 
	    input select,
	    output reg [31:0]out
	   );
	   
	always @* 
		if (select) out = case_1;
		else out = case_0;
endmodule

module ALU ( input [31:0] srcA, srcB, 
	     input [3:0] ALUControl,
	     output reg [31:0] res
	    );
	always @*
		casez (ALUControl)
		4'b0000: //+
		res = srcA + srcB;
		4'b0001: //-
		res = srcA - srcB;
		4'b0010: //AND 
		res = srcA & srcB;
		4'b0011: //OR 
		res = srcA | srcB;
		4'b0100: //< 
		res =  $signed(srcA) < $signed(srcB);
		4'b0101: //div
		res = srcA / srcB;
		4'b0110: //rem
		res = srcA % srcB;
		4'b0111: //==
		res = srcA == srcB;
		4'b1000: //<<
		res = srcA << srcB;
		4'b1001: // >> (unsigned)
		res = srcA >>> srcB;
		4'b1010: // >> (signed)
		res = $signed(srcA) >>> srcB;
	endcase
endmodule

module register (input [31:0] in, 
		 input clk, reset,
		 output reg [31:0] out
		 );
	
	always @(posedge clk or posedge reset) begin
		if (reset) out = 32'b0; 
		else out = in;	 
	end
endmodule

module GPRSet ( input [4:0] A, B, C, 
		input [31:0] wd,
		input clk, we, 
		output [31:0] rd1, rd2
		);
	
	reg [31:0] regs[31:0];
	
	always @(posedge clk)
		if (we) regs[C] = wd;
		
	assign rd1 = (A == 0) ? 32'b0 : regs[A];
	assign rd2 = (B == 0) ? 32'b0 : regs[B];
endmodule

module luiImmAdder ( input [19:0] imm,
	  	     output [31:0] out
	  	    );
	assign out = {imm, 12'b0}; 	    
endmodule



































