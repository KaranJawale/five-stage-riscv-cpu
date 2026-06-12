//testbench
`timescale 1ns/1ps

module RISCV_CPU_tb;

	//Input to the dut
	reg clock;

	//Clock initialisation
	initial begin
		clock = 0;
		forever #5 clock = ~clock;
	end
	
	//dut instantiation
	RISCV_CPU dut(
		.clock(clock)
	);
	
	//Pipeline initialisation
	initial begin
		#1; 
	
		//register file loading
		dut.RegFile[1] = 10;
		dut.RegFile[2] = 20;
		
		//Insturction memory loading
		dut.IMemory[0] = 32'h0020_81B3;		//add x3, x1, x2 = 
		//dut.IMemory[1] = 32'h0011_8233;
		dut.IMemory[1] = 32'h0000_0013;		//NOP
		dut.IMemory[2] = 32'h0000_0013;		//NOP
		dut.IMemory[3] = 32'h0000_0013;		//NOP
		dut.IMemory[4] = 32'h0000_0013;		//NOP
		dut.IMemory[5] = 32'h0011_8233;		//add x4, x3, x1
	end
	
	//Analysis
	//Initial monitor
	initial begin
		$display("==============================================================");
      $display("Time\tPC\tx1\tx2\tx3\tx4");
      $display("==============================================================");

      $monitor("\n%0t\t%0d\t%0d\t%0d\t%0d\t%0d",
                 $time,
                 dut.PC,
                 dut.RegFile[1],
                 dut.RegFile[2],
                 dut.RegFile[3],
                 dut.RegFile[4]);
	end
	
	//Pipeline monitor
	always @ (posedge clock) begin
	#1;
	
		$display("\nTime\t%t", $time);
		$display("PC:%d\nIFIDIR:%h\nIDEX_rs1_DATA:%d\nIDEX_rs2_DATA:%d\nIDEXIR:%h\nEXMEMALU_OUT:%d\nST_DATA_MEM:%d\nEXMEMIR:%h\nWR_DATA:%d\nMEMWBIR:%h\nMEMWBrd:%d", 
		dut.PC, 
		dut.IFIDIR,
		dut.IDEX_rs1_DATA,
		dut.IDEX_rs2_DATA,
		dut.IDEXIR,
		dut.EXMEMALU_OUT,
		dut.ST_DATA_MEM,
		dut.EXMEMIR,
		dut.WR_DATA,
		dut.MEMWBIR,
		dut.MEMWBrd);
	end
	
	//Pass/Fail test
	initial begin
	
		#200;
	
		if(dut.RegFile[3] == 30 && dut.RegFile[4] == 40) begin
			$display("TEST PASSED");
		end
		
		else begin
			$display("TEST FAILED");
			$display("Expected : Reg[3]:30, Reg[4]=40");
			$display("Result : Reg[3]:%d, Reg[4]=%d", dut.RegFile[3], dut.RegFile[4]);
		end
		
		 $finish;
		
	end
	
endmodule