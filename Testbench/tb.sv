// Code your testbench here
// or browse Examples
module tb;
  reg clk, rst;
  
  CPU cpu_inst 
  (.clk(clk),
   .rst(rst)
  );
  
  always #1 clk = ~clk;
  
  initial begin
    clk = 0; rst = 1;
    cpu_inst.top_cont_inst.reg_inst.Registers[1] = 32'h40000000;
    cpu_inst.top_cont_inst.reg_inst.Registers[2] = 32'h40400000;
    cpu_inst.pc_inst.Imem[0] = {2'b00, 5'b00000, 5'b00011, 5'b00001, 5'b00010, 5'b00000, 32'b0};
    cpu_inst.pc_inst.Imem[1] = {2'b01, 5'b00000, 5'b00011, 5'b00001, 5'b00010, 5'b00000, 32'b0};
    #5;
    rst = 0;
  end
  
  initial begin
   $dumpfile("dump.vcd"); $dumpvars; 
  end
  
  initial begin
    #200;
    $finish;
  end
  
endmodule