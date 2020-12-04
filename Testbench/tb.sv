// Code your testbench here
// or browse Examples
module tb;
  reg clk, rst;
  
  // CPU instance
  
  CPU cpu_inst 
  (.clk(clk),
   .rst(rst)
  );
  
  // Clock generation
  always #1 clk = ~clk;
  
  initial begin
    clk = 0; rst = 1; //Initialise clock and give rst to execute first instruction
    cpu_inst.top_cont_inst.reg_inst.Registers[1] = 32'h40000000; // Register 1 of register bank is initialised with 2.0
    cpu_inst.top_cont_inst.reg_inst.Registers[2] = 32'h40400000; // Register 2 of register bank is initialised with 3.0
    cpu_inst.pc_inst.Imem[0] = {2'b00, 5'b00000, 5'b00011, 5'b00001, 5'b00010, 5'b00000, 32'b0}; 
	// 1st instruction is loaded in PC. 
	// 1st instruction is content(R1) + content(R2) = content(R3) 
	//--> R type add instruction indicated by flag(00) and opcode(00000)
	// {i.e., 2.0+3.0 is stored in R3}
    cpu_inst.pc_inst.Imem[1] = {2'b01, 5'b00000, 5'b00011, 5'b00001, 5'b00010, 5'b00000, 32'b0}; 
	// 2nd instruction is loaded in PC.
	// 2nd instruction is content(R1) + 32 bit immediate value = content(R3) 
	//--> I type add instruction indicated by flag(01) and opcode(00000)
	// {i.e., 2.0+0.0 is stored in R3}
    #5;
    rst = 0;//Make reset 0 to execute subsequent instructions
  end
  
  initial begin
   $dumpfile("dump.vcd"); $dumpvars; //Wave dumping
  end
  
  initial begin
    #200;
    $finish; //Simulation stop after 200 timeunits
  end
  
  
  always@(posedge cpu_inst.fetch_stage_enable)begin // At every positive edge of fetch_stage_enable i.e., at end of every instruction complete print program counter value, Rd, content(Rd) 
    $display("program counter - %d | Register destination address - %d | Destination value - %h", cpu_inst.program_counter, cpu_inst.top_cont_inst.reg_inst.WriteReg, cpu_inst.top_cont_inst.reg_inst.WriteData);  
  end
  
endmodule