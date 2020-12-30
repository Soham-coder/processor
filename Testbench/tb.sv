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
  
  initial begin //(In this block initialise register file and store instructions in program counter)
                                      //Initialise clock
    clk = 0;  
                                      //#######LOAD REGISTER FILE########//

    cpu_inst.top_cont_inst.reg_inst.Registers[1] = 32'h40000000; // Register 1 of register bank is initialised with 2.0
    cpu_inst.top_cont_inst.reg_inst.Registers[2] = 32'h40400000; // Register 2 of register bank is initialised with 3.0

                                      //#######LOAD INSTRUCTIONS########//

    cpu_inst.pc_inst.Imem[0] = {2'b00, 5'b00000, 5'b00011, 5'b00001, 5'b00010, 5'b00000, 32'b0}; 
	/*
	 + Instruction 1 = {2'b00, 5'b00000, 5'b00011, 5'b00001, 5'b00010, 5'b00000, 32'b0}
     # Flag(00) - Register operation
     # Opcode(00000) - ADD operation
     # Rd(00011) - Destination Register address = 3
     # Rs1(00001) - Source_1 Register address = 1
     # Rs2(00010) - Source_2 Register address = 2
     # Program_counter_value(00000) - Current instruction number = 0
     # 32_bit immediate value(32'b0) - 32_bit immediate value = 32'b0

     Instruction 1 is loaded in PC[0]- 
     1st instruction is content(R1) + content(R2) = content(R3) 
     # R type add instruction indicated by flag(00) and opcode(00000)
     {i.e., 2.0+3.0=5.0 should be stored in R3 after this operation}
    */
    cpu_inst.pc_inst.Imem[1] = {2'b01, 5'b00000, 5'b00011, 5'b00001, 5'b00010, 5'b00001, 32'b0}; 
	/*
	 + Intruction 2 = {2'b01, 5'b00000, 5'b00011, 5'b00001, 5'b00010, 5'b00000, 32'b0}
     # Flag(01) - Immediate operation
     # Opcode(00000) - ADD operation
     # Rd(00011) - Destination Register address = 3
     # Rs1(00001) - Source_1 Register address = 1
     # Rs2(00010) - Source_2 Register address = 2
     # Program_counter_value(00001) - Current instruction number = 1
     # 32_bit immediate value(32'b0) - 32_bit immediate value = 32'b0

     Instruction 2 is loaded in PC[1]- 
     2nd instruction is content(R1) + 32 bit immediate value = content(R3) 
     # I type add instruction indicated by flag(01) and opcode(00000)
     {i.e., 2.0+0.0=2.0 should be stored in R3 after this operation}
	*/

  cpu_inst.pc_inst.Imem[2] = {2'b00, 5'b00001, 5'b00011, 5'b00001, 5'b00010, 5'b00010, 32'b0}; 
	/*
	 + Instruction 3 = {2'b00, 5'b00001, 5'b00011, 5'b00001, 5'b00010, 5'b00010, 32'b0}
     # Flag(00) - Register operation
     # Opcode(00001) - MUL operation
     # Rd(00011) - Destination Register address = 3
     # Rs1(00001) - Source_1 Register address = 1
     # Rs2(00010) - Source_2 Register address = 2
     # Program_counter_value(00010) - Current instruction number = 2
     # 32_bit immediate value(32'b0) - 32_bit immediate value = 32'b0

     Instruction 3 is loaded in PC[2]- 
     3rd instruction is content(R1) + content(R2) = content(R3) 
     # R type mult instruction indicated by flag(00) and opcode(00001)
     {i.e., 2.0*3.0 = 6.0 should be stored in R3 after this operation}
    */
    cpu_inst.pc_inst.Imem[3] = {2'b01, 5'b00001, 5'b00011, 5'b00001, 5'b00010, 5'b00011, 32'b0}; 
	/*
	 + Intruction 4 = {2'b01, 5'b00001, 5'b00011, 5'b00001, 5'b00010, 5'b00011, 32'b0}
     # Flag(01) - Immediate operation
     # Opcode(00001) - MUL operation
     # Rd(00011) - Destination Register address = 3
     # Rs1(00001) - Source_1 Register address = 1
     # Rs2(00010) - Source_2 Register address = 2
     # Program_counter_value(00011) - Current instruction number = 3
     # 32_bit immediate value(32'b0) - 32_bit immediate value = 32'b0

     Instruction 4 is loaded in PC[3]- 
     4th instruction is content(R1) + 32 bit immediate value = content(R3) 
     # I type mult instruction indicated by flag(01) and opcode(00001)
     {i.e., 2.0*0.0=0.0 should be stored in R3 after this operation}
	*/
  end
  
  


  
  initial begin
  #5;
  rst = 1; //Give Reset to execute first instruction
  #5;
  rst = 0; //Make reset 0 to execute subsequent instructions
  end
  
  initial begin
   $dumpfile("dump.vcd"); $dumpvars; //Wave dumping
  end
  
  initial begin
    #400;
    $finish; //Simulation stop after 400 timeunits
  end
  
  
  always@(posedge cpu_inst.fetch_stage_enable)begin // At every positive edge of fetch_stage_enable i.e., at end of every instruction complete print program counter value, Rd, content(Rd) 
    $display("program counter - %d | Register destination address - %d | Destination value - %h", cpu_inst.program_counter, cpu_inst.top_cont_inst.reg_inst.WriteReg, cpu_inst.top_cont_inst.reg_inst.WriteData);  
  end
  
endmodule