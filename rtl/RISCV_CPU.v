//RISCV CPU with forwarding logic

`timescale 1ns/1ps

module RISCV_CPU(clock);

	input clock;
	
	parameter RTYPE = 7'b0110_011;
	parameter LD = 7'b0000_011;
	parameter SD = 7'b0100_011;
	parameter BEQ = 7'b1100_011;
	parameter NOP = 32'h0000_0013;
	
	reg [31:0] IMemory [1023:0];		//1024 32-bit registers; RISC-V uses 32 bit instructions
	reg [63:0] DMemory [1023:0];		//1024 64-bit registers; Data is 64 bits in size in RISC-V
	reg [63:0] RegFile [31:0]; 		//32 general purpose registers
	
	//Pipeline instruction registers
	//Instruction flow from one stage to the next
	reg [31:0] IFIDIR;
	reg [31:0] IDEXIR;
	reg [31:0] EXMEMIR;
	reg [31:0] MEMWBIR;
	reg [31:0] PC;
	
	//Pipeline register operands; Decoded operands
	wire [4:0] IFIDrs1;		//Read register 1 number; Instruction in the ID stage
	wire [4:0] IFIDrs2; 		//Read register 2 number
	wire [4:0] IDEXrs1;		//Read register 1 number; Instruction in the EX stage
	wire [4:0] IDEXrs2;		//Read register 2 number;
	wire [4:0] EXMEMrd;		//Destination register number; Instruction in the MEM stage
	wire [4:0] MEMWBrd; 		//Destination register number; Instruction in the WB stage
	wire [63:0] Ain, Bin;	//Inputs to the ALU
	//Assignments
	assign IFIDrs1 = IFIDIR[19:15];
	assign IFIDrs2 = IFIDIR[24:20];
	assign IDEXrs1 = IDEXIR[19:15];
	assign IDEXrs2 = IDEXIR[24:20];
	assign EXMEMrd = EXMEMIR[11:7];
	assign MEMWBrd = MEMWBIR[11:7];
	
	//Pipeline data registers
	//Data flow in a stage
	//reg [63:0] ALU_OUT;		//Stores the 64-bit result of the ALU operation
	reg [63:0] WR_DATA; 		//Write data to the register file
	reg [63:0] IDEX_rs1_DATA;			//Register to hold Read register 1 data
	reg [63:0] IDEX_rs2_DATA;			//Register to hold Read register 2 data
	reg [63:0] ST_DATA_MEM;		//Register to hold the store data for the store instruction in the
										//MEM stage
	reg [63:0] EXMEMALU_OUT;	//Transfers the ALU result to the next stage
	
	//Bypass signals
	wire bypassA_MEM;
	wire bypassA_ALU_WB;
	wire bypassA_LD_WB;
	
	wire bypassB_MEM;
	wire bypassB_ALU_WB;
	wire bypassB_LD_WB;

	//FORWARDING LOGIC
	//Bypass to the input A of the ALU for the instruction in the EX stage from the ALU output
	//of the instruction in the MEM stage
	assign bypassA_MEM = (IDEXrs1 == EXMEMrd) && (EXMEMrd != 0) && (EXMEMIR[6:0] == RTYPE);
	//Bypass to the input A of the ALU for an instruction in the EX stage from the ALU output
	//of the instruction in the WB stage
	assign bypassA_ALU_WB = (IDEXrs1 == MEMWBrd) && (MEMWBrd != 0) && (MEMWBIR[6:0] == RTYPE);
	//Bypass to the input A of the ALU for an instruction in the EX stage from
	//memory output of the instruction in the WB stage
	assign bypassA_LD_WB = (IDEXrs1 == MEMWBrd) && (MEMWBrd != 0) && (MEMWBIR[6:0] == LD);
	
	//Bypass to the input B of the ALU for the instruction in the EX stage from the ALU output
	//of the instruction in the MEM stage
	assign bypassB_MEM = (IDEXrs2 == EXMEMrd) && (EXMEMrd != 0) && (EXMEMIR[6:0] == RTYPE);
	//Bypass to the input B of the ALU for an instruction in the EX stage from the ALU output
	//of the instruction in the WB stage
	assign bypassB_ALU_WB = (IDEXrs2 == MEMWBrd) && (MEMWBrd != 0) && (MEMWBIR[6:0] == RTYPE);
	//Bypass to the input B of the ALU for an instruction in the EX stage from
	//memory output of the instruction in the WB stage
	assign bypassB_LD_WB = (IDEXrs2 == MEMWBrd) && (MEMWBrd != 0) && (MEMWBIR[6:0] == LD);
	
	//The input A to the ALU comes from MEM stage if there is a bypass or from the WB stage of there is
	//a bypass or from the Register file
	assign Ain = bypassA_MEM ? EXMEMALU_OUT : 
									((bypassA_ALU_WB || bypassA_LD_WB) ? WR_DATA : IDEX_rs1_DATA);
	
	assign Bin = bypassB_MEM ? EXMEMALU_OUT : 
									((bypassB_ALU_WB || bypassB_LD_WB) ? WR_DATA : IDEX_rs2_DATA);
	
	integer i;
	
	//Initialisation of the registers
	initial begin
			
			//Pipeline instruction registers
			IFIDIR = NOP;
			IDEXIR = NOP;
			EXMEMIR = NOP;
			MEMWBIR = NOP;
			PC = 0;
			
			//Instruction cache
			for (i = 0; i < 1024; i = i + 1) begin
				IMemory[i] = NOP;
			end
			
			//Data memory cache
			for(i = 0; i < 1024; i = i + 1) begin
				DMemory[i] = 0;
			end
			
			//Register file
			for(i = 0; i < 32; i = i + 1) begin
				RegFile[i] = i;
			end
			
			//Data flow registers
			//ALU_OUT = 0;
			WR_DATA = 0;
			IDEX_rs1_DATA = 0;
			IDEX_rs2_DATA = 0;
			ST_DATA_MEM = 0;
			EXMEMALU_OUT = 0;
	end
	
	always @ (posedge clock) begin
		//IF STAGE
		IFIDIR <= IMemory[PC >> 2];	//PC is byte addressable
		PC <= PC + 4;
		
		//ID STAGE
		IDEX_rs1_DATA <= RegFile[IFIDrs1];		//Read register 1 data
		IDEX_rs2_DATA <= RegFile[IFIDrs2];		//Read register 2 data
		IDEXIR <= IFIDIR;							//Pass the instruction to the next stage
		
		case (IDEXIR[6:0])
			LD : EXMEMALU_OUT <= Ain + {{52{IDEXIR[31]}}, IDEXIR[31:20]};
				
			SD : EXMEMALU_OUT <= Ain + {{52{IDEXIR[31]}}, IDEXIR[31:25], IDEXIR[11:7]};
			
			RTYPE : begin
				case ({IDEXIR[30], IDEXIR[14], IDEXIR[13], IDEXIR[12]})
					4'b0000 : EXMEMALU_OUT <= Ain + Bin;
					4'b1000 : EXMEMALU_OUT <= Ain - Bin;
					4'b0111 : EXMEMALU_OUT <= Ain & Bin;
					4'b0110 : EXMEMALU_OUT <= Ain | Bin;
					default : ;
				endcase
			end
			
			BEQ : EXMEMALU_OUT <= Ain - Bin; //Check if the two operands are equal
			
			default :;
		endcase
		
		//EXMEMALU_OUT <= ALU_OUT;
		ST_DATA_MEM <= IDEX_rs2_DATA;
		EXMEMIR <= IDEXIR;
		
		//MEM STAGE
		case(EXMEMIR[6:0])
			LD : WR_DATA <= DMemory[EXMEMALU_OUT >> 3];
			SD : DMemory[EXMEMALU_OUT >> 3] <= ST_DATA_MEM;
			RTYPE : WR_DATA <= EXMEMALU_OUT;
			BEQ : ;
			default : WR_DATA <= WR_DATA;
		endcase
		
		MEMWBIR <= EXMEMIR;
		
		//WB STAGE
		if(((MEMWBIR[6:0] == LD) || (MEMWBIR[6:0] == RTYPE)) && (MEMWBIR[11:7] != 0)) begin
			RegFile[MEMWBrd] <= WR_DATA;
		end
	end
	
endmodule