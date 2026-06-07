`timescale 1ns/1ps

module RISCV_PIPELINE_tb; 
	
	//Input to the dut
	reg clock;
	
	//dut instantiation
	RISCV_PIPELINE dut(
		.clock(clock)
	);
	
	//Clock Generation
	initial begin
		clock = 0;
		forever #5 clock = ~clock;
	end
	
	//Program and register initialisation
	integer i;
	
	initial begin
		
		//Initialising instruction memory with NOPs
		for(i = 0; i < 1024; i =  i + 1)
			dut.IMemory[i] = 32'h00000013;     // addi x0,x0,0; NOP
			
		//Loading Program instructions
		//add x3, x1, x2;
		dut.IMemory[0] = 32'h002081B3;
		
		//nop
		dut.IMemory[1] = 32'h00000013;
		dut.IMemory[2] = 32'h00000013;
		dut.IMemory[3] = 32'h00000013;
		
		//add x4, x3, x1
		dut.IMemory[4] = 32'h00118233;
		
		//Register file initialisation
		#1;
		dut.Regs[1] = 10;
		dut.Regs[2] = 20;
	end
	
	//Monitor Register Results
	initial begin

        $display("==============================================================");
        $display("Time\tPC\tx1\tx2\tx3\tx4");
        $display("==============================================================");

        $monitor("%0t\t%0d\t%0d\t%0d\t%0d\t%0d",
                 $time,
                 dut.PC,
                 dut.Regs[1],
                 dut.Regs[2],
                 dut.Regs[3],
                 dut.Regs[4]);

    end
	 
	 //Pipeline Trace
	 always @(posedge clock)
    begin

        $display(
            "\nT=%0t",
            $time
        );

        $display("PC       = %0d", dut.PC);

        $display("IF/ID IR = %h", dut.IFIDIR);
        $display("ID/EX IR = %h", dut.IDEXIR);
        $display("EX/MEMIR = %h", dut.EXMEMIR);
        $display("MEM/WBIR = %h", dut.MEMWBIR);

        $display("IDEXA    = %0d", dut.IDEXA);
        $display("IDEXB    = %0d", dut.IDEXB);

        $display("ALUOUT   = %0d", dut.EXMEMALUOut);
        $display("WBVALUE  = %0d", dut.MEMWBValue);

    end
	 
	 //Pass/Fail Check
	 initial begin

        #100;

        $display("\n");
        $display("==============================================================");

        if ((dut.Regs[3] == 30) &&
            (dut.Regs[4] == 40))
        begin
            $display("TEST PASSED");
        end
        else
        begin
            $display("TEST FAILED");
            $display("x3 = %0d (Expected 30)", dut.Regs[3]);
            $display("x4 = %0d (Expected 40)", dut.Regs[4]);
        end

        $display("==============================================================");

        $finish;

    end
endmodule