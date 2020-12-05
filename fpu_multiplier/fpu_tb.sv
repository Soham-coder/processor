// Code your testbench here
// or browse Examples
module tb;
  reg [31:0] a, b;
  reg mult_input_STB;
  wire mult_BUSY;
  reg clk;
  reg rst;
  wire [31:0] output_mult;
  wire mult_output_STB;
  reg output_module_BUSY;
  
  reg transaction;
  assign transaction = (mult_input_STB && !(mult_BUSY));//Indicates when actually data is being taken by multiplier module
  
  multiplier multiplier_fpu_inst //multiplier instantiation
  (.input_a(a), 
   .input_b(b), 
   .mult_input_STB(mult_input_STB), 
   .mult_BUSY(mult_BUSY), 
   .clk(clk), 
   .rst(rst),
   .output_mult(output_mult),
   .mult_output_STB(mult_output_STB),
   .output_module_BUSY(output_module_BUSY)
  );
  
  always #5 clk = ~clk; //Clock generation
  
  initial begin
    $dumpfile("dump.vcd");//Signals are dumped in vcd starting at 0 time until $finish. 
    $dumpvars;//All variables are dumped both in tb and DUT.
    rst = 1; clk = 0; mult_input_STB = 0 ; output_module_BUSY = 0; //First reset is given output should be in don't care condition, clock is initialized to 0 and BUSY signal of output module connected to multiplier is driven low, i.e., output module is always ready to accept data whenever valid data comes to it.
    #10;
    rst = 0; //After some delay reset is turned low and STB is made high and valid operands are given. These operands are taken by multiplier just in the next clock since BUSY was low. 
    mult_input_STB = 1 ; 
    a = 'h40000000;//2
    b = 'h40400000;//3
    #10; //After some delay STB is high already and valid operands are given. But these operands are taken after several clock cycles later because BUSY is now high.So transaction only takes place when STB=1 and BUSY = 0 indicated by the transaction signal several clock cycles later i.e., after the current one is finished. 
    a = 'h40800000;//4
    b = 'h40a00000;//5
    #150;
    mult_input_STB = 0 ; //After several clocks STB is made low since no more valid operands to give to multiplier for further processing.
    //#20;
    #250;
    $finish; //Simulation is stopped after some more clock cycles.
  end
  
  initial begin
    $monitor("Time-%t, input_a-%h, input_b-%h, output_product-%h", $time, a, b, output_mult);//Monitor these signals anytime any of them change starting from 0 time.
  end
endmodule
