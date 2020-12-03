///////////////////PROGRAM COUNTER////////////////////
////////////////////////ROM///////////////////////////
module program_counter(pc_address,dout);

parameter depth =256;
parameter pc_width = 5;
parameter instr_width = 59;


input [pc_width-1:0] pc_address; //pc_address coming from instruction_decode controller 5 bits wide = 32 addresses are possible as of now
output [instr_width-1:0] dout; //59 bit wide instruction

reg [instr_width-1:0] Imem[depth-1:0]; //256 registers each of 59 bit wide

//Continuos assignment    
assign dout= Imem[pc_address]; //instruction is always available whenever pc_address is given

endmodule
