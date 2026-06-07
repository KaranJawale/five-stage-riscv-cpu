module RISCV_PIPELINE(clock);
	
	input clock;
	
	//OpCode definitions
	parameter LD = 7'b000_0011;
	parameter SD = 7'b010_0011;
	parameter BEQ = 7'b110_0011;
	parameter NOP = 32'h0000_0013;
	parameter RTYPE = 7'b011_0011;
	
	//Memories and Register Files
	reg [31:0] IMemory [1023:0];		//Instruction Memory
	reg [31:0] DMemory [1023:0];		//Data Memory
	reg [63:0] Regs [31:0];				//32 64-bit General purpose Registers
	
	//Pipeline Registers (Instruction Path)
	//Each holds the entire instruction
	reg [31:0] IFIDIR;
	reg [31:0] IDEXIR;
	reg [31:0] EXMEMIR;
	reg [31:0] MEMWBIR;
	
	//Pipeline Registers (Data Path)
	//Registers to hold the data flowing through a stage
	reg [63:0] PC;		//Program Counter
	reg [63:0] IDEXA; //Read Register1 Data
	reg [63:0] IDEXB;	//Read Register2 Data
	reg [63:0] EXMEMALUOut; //Output of ALU
	reg [63:0] MEMWBValue; 	//Write Data
	
	//Decoded Fields
	wire [4:0] IFIDrs1;		//Number of Read Register 1
	wire [4:0] IFIDrs2;		//Number of Read Register 2
	wire [4:0] MEMWBrd;		//destination Register/Write register number
									//Provided by the MEM/WB Pipeline Register
									
	wire [6:0] Opcode;
	
	//Assignments define the fields from pipeline registers
	assign IFIDrs1 = IFIDIR[19:15];
	assign IFIDrs2 = IFIDIR[24:20];
	assign MEMWBrd = MEMWBIR[11:7];
	assign Opcode = IFIDIR[6:0];
	
	//Initialization
	integer i = 0;
	
	initial 
	begin
		PC = 0;		//Program Counter starts at 0
		
		IFIDIR = NOP;		//Pipeline registers initialized to NOPs
		IDEXIR = NOP;
		EXMEMIR = NOP;
		MEMWBIR = NOP;
		
		//Registers initialized
		for (i = 0; i < 32; i = i + 1)
		begin
			Regs[i] = i;
		end
	end
	
	//Main Pipeline Logic
	//All stages run every cycle
	
	always @ (posedge clock)
	begin
		//IF Stage
		IFIDIR <= IMemory[PC >> 2];
		PC <= PC + 4;
		
		//ID Stage
		IDEXA <= Regs[IFIDrs1];		//Read register
		IDEXB <= Regs[IFIDrs2];
		IDEXIR <= IFIDIR;		      //Passing instruction forward
		
		//EXE Stage
		case(IDEXIR[6:0])
		
			LD :  EXMEMALUOut <= IDEXA + {{52{IDEXIR[31]}}, IDEXIR[31:20]};
			
			SD : EXMEMALUOut <= IDEXA + {{52{IDEXIR[31]}}, IDEXIR[31:25], IDEXIR[11:7]};
			
			RTYPE : begin
				case ({IDEXIR[30], IDEXIR[14], IDEXIR[13], IDEXIR[12]})
				
					4'b0000 : EXMEMALUOut <= (IDEXA + IDEXB);	//ADD operation
					
					4'b1000 : EXMEMALUOut <= (IDEXA - IDEXB); 	//SUB operation 
					
					4'b0111 : EXMEMALUOut <= (IDEXA & IDEXB); 	//Bitwise AND
					
					4'b0110 : EXMEMALUOut <= (IDEXA | IDEXB);	//Bitwise OR
					
					default : ;//Unsupported Rtype instruction
				endcase
			end
			
			//default : EXMEMALUOut <= 0;
			
		endcase
		EXMEMIR <= IDEXIR;	//Passing instruction forward
		
		//MEM Stage
		case (EXMEMIR[6:0])
		
			LD : MEMWBValue <= DMemory[EXMEMALUOut >> 2];
			
			SD : DMemory[EXMEMALUOut >> 2] <= IDEXB;
			
			default: MEMWBValue <= EXMEMALUOut;
			
		endcase
		MEMWBIR <= EXMEMIR;		//Passing instruction forward

		//WB Stage
		if ((MEMWBIR[6:0] == LD || MEMWBIR[6:0] == RTYPE) && (MEMWBrd != 0)) begin
					Regs[MEMWBrd] <= MEMWBValue;
			  end
			  
	end
	
endmodule