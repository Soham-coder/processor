///////////////////PROGRAM COUNTER////////////////////
//////////////////////// Instruction - ROM ///////////////////////////

`include "../defines.vh"

module program_counter(pc_address,dout);

localparam  NUMBER_OF_PC_REGISTERS = `NUMBER_OF_PC_REGISTERS;
localparam  PC_WIDTH = $clog2(NUMBER_OF_PC_REGISTERS);
localparam  OPERATION_TYPE_WIDTH = `OPERATION_TYPE_WIDTH;
localparam  OPCODE_WIDTH = `OPCODE_WIDTH;
localparam  NUMBER_OF_REGISTERS = `NUMBER_OF_REGISTERS;
localparam  ADDR_WIDTH = $clog2(NUMBER_OF_REGISTERS);
localparam  WORD_SIZE = `WORD_SIZE;
localparam  INSTR_WIDTH = OPERATION_TYPE_WIDTH + OPCODE_WIDTH + 3*ADDR_WIDTH + PC_WIDTH + WORD_SIZE; 



input [PC_WIDTH - 1:0] pc_address; //pc_address coming from instruction_decode controller 5 bits wide = 32 addresses are possible as of now
output [INSTR_WIDTH - 1:0] dout; //59 bit wide instruction

reg [INSTR_WIDTH - 1:0] Imem[NUMBER_OF_PC_REGISTERS - 1:0]; //256 registers each of 59 bit wide

//Continuos assignment    
assign dout= Imem[pc_address]; //instruction is always available whenever pc_address is given

endmodule
