
`include "../defines.vh"
`include "../fpu_multiplier/fpu_mult.v" //It's the same as full code of fpu_mult coming and sitting in this place

module mult_controller //Does mult_register or mult_immediate operations 
(
 clk, 
 rst, 
 start, 
 pc, 
 next_pc,  
 done, 
 busy, 
 operation_type, 
 source_1_address, 
 source_2_address, 
 destination_address, 
 source_immediate_value, 
 rs1, 
 rs2, 
 rd, 
 source_1_value, 
 source_2_value, 
 destination_value, 
 write_enable
 );


localparam  OPERATION_TYPE_WIDTH = `OPERATION_TYPE_WIDTH;
localparam  NUMBER_OF_PC_REGISTERS = `NUMBER_OF_PC_REGISTERS;
localparam  PC_WIDTH = $clog2(NUMBER_OF_PC_REGISTERS);
localparam  WORD_SIZE = `WORD_SIZE;
localparam  NUMBER_OF_REGISTERS = `NUMBER_OF_REGISTERS;
localparam  ADDR_WIDTH = $clog2(NUMBER_OF_REGISTERS);

input clk;//clock
input rst;//reset
input start;//operation start signal given by instruction decode controller

input [OPERATION_TYPE_WIDTH - 1:0] operation_type; //R or I type  e.g.,  MULT Rd, Rs1, Rs2 (R-Type)  |  MULTI Rd, Rs1, immediate_value (I-Type) 
input [PC_WIDTH - 1:0] pc; //Current program counter value given by instruction_decode controller   

output [PC_WIDTH - 1:0] next_pc; //Next program counter value given by instruction decode controller
output busy; //Indicates that operation of this controller is still going on
output done; //Indicates that operation of this controller is complete

input [ADDR_WIDTH - 1:0] source_1_address; //Rs1- source address 1 , This controller will go to this address of register file and fetch operand_1
input [ADDR_WIDTH - 1:0] source_2_address; //Rs2- source address 2, This controller will go to this address of register file and fetch operand_2 
input [ADDR_WIDTH - 1:0] destination_address; //Rd destination address, This controller will go to this address of register file and write the resultant value
//(i.e., sum output obtained by FPU multiplier)

output [ADDR_WIDTH - 1:0] rs1, rs2, rd; //This is the output address to be given to register file for reading operands and writing result

input [WORD_SIZE - 1:0] source_immediate_value;//Immediate value given by instruction decode controller in case of immediate operation to be done
input [WORD_SIZE - 1:0] source_1_value;//Value of 1st operand that will be given by register file
input [WORD_SIZE - 1:0] source_2_value;//Value of 2nd operand that will be given by register file

output [WORD_SIZE - 1:0] destination_value;//Resultant value(i.e., sum output obtained from FPU multiplier) that will be written to register file
output write_enable;//Write enable output signal given by this controller to register file in case of write

//Internal registers
reg output_STB_to_multiplier; //Input STB to multiplier indicating valid inputs
reg multiplier_is_BUSY; //Output BUSY status of multiplier indicating that it is busy
reg input_STB_to_controller; //STB given by multiplier to controller indicating valid multiplier result
reg BUSY_to_multiplier; //Indicating whether controller is busy i.e., if it can take valid result of multiplier or not at this moment or not
reg [WORD_SIZE - 1:0] output_mult; //Output multiplier as obtained by FPU multiplier 
reg [WORD_SIZE - 1:0] destination_reg, destination_temp; //Immediate variables
reg busy_temp, done_temp; //Immediate variables
reg [WORD_SIZE - 1:0] source_1_reg, source_2_reg, source_1_temp, source_2_temp ; //Immediate variables
reg [PC_WIDTH - 1:0] pc_new_reg, pc_new_temp;//Immediate variables
reg [ADDR_WIDTH - 1:0] rs1_reg, rs2_reg , rd_temp; //Immediate variables
reg [ADDR_WIDTH - 1:0] rd_reg;//Immediate variables
reg write_enable_temp;//Immediate variable


//FPU_multiplier_instance
  multiplier fpu_mult_inst (.input_a(source_1_reg), 
                            .input_b(source_2_reg), 
                            .mult_input_STB(output_STB_to_multiplier), 
                            .mult_BUSY(multiplier_is_BUSY), 
                            .clk(clk), 
                            .rst(rst), 
                            .output_mult(output_mult), 
                            .mult_output_STB(input_STB_to_controller) , 
                            .output_module_BUSY(BUSY_to_multiplier)
                            ); 

reg [3:0] mult_cnt_state;//State variable to store current state
 
//Output assignments
assign rs1 = rs1_reg;
assign rs2 = rs2_reg;
assign rd = rd_temp;
assign write_enable = write_enable_temp;
assign next_pc = pc_new_temp;
assign busy = busy_temp;
assign done = done_temp;
assign destination_value = destination_temp;

//Parameterization of Operation Type and Internal States 
parameter R=2'd0,
          I=2'd1;

parameter give_address_to_register_file=3'd0,
          latch_inputs=3'd1,
          start_multiplier=3'd2,
          wait_for_multiplier_complete=3'd3,
          write_back_to_register=3'd4,
          wait_one_cycle=3'd5,
          increment_pc_and_update_status=3'd6;

always @(posedge clk)begin//always
 
 case (mult_cnt_state)
 
 give_address_to_register_file:
 begin//State- Give address to register file
   if(start)begin //If start given by instruction decode controller, then only do something or start operation and transition to next state, 
   //otherwise remain in the same state
   write_enable_temp <= 0; //No writing to register file in this stage because output mult is yet not ready, If it is on then wrong value will be written to Register File. 
   busy_temp <= 1; //Make busy signal high
   done_temp <= 0;//Make done signal as 0 because controller has just started operation
   pc_new_reg <= pc; //Latch current pc value as obtained by instruction decode controller
   rs1_reg <= source_1_address; //Give source address 1 (as given by instruction decode controller) to register file for reading 1st operand 
   rs2_reg <= source_2_address; //Give source address 2 (as given by instruction decode controller) to register file for reading 2nd operand 
   rd_reg <= destination_address; //Give destination address to register file (as given by instruction decode controller) for writing resultant mult output
   mult_cnt_state <= latch_inputs; //Go to next state of latching inputs
   end
   else begin
   mult_cnt_state <= give_address_to_register_file; //If not start given by instruction decode controller, wait in the same state
   write_enable_temp <= 0;//No writing to register file in this stage because output mult is yet not ready, If it is on then wrong value will be written to Register File.
   busy_temp <= 0; //Make busy signal low
   end
 end//
 
 
 latch_inputs:
 begin//// Latch inputs
 source_1_temp <= source_1_value; // Latch value of source_1 operand as given by address rs1 by register file
 mult_cnt_state <= start_multiplier;//Go to next state of starting the multiplier
 case(operation_type)// For selecting source_2 operand either take either register value as given by rs2 address by register file or 
 //take immediate value based on operation_type flag (R or I)
 R:
 begin
 source_2_temp <= source_2_value; //Register Operation(R)? - Take value given by Register File
 end
 I:
 begin
 source_2_temp <= source_immediate_value; //Immediate Operation(I)? - Take immediate value given by Instruction decode controller 
 end
 endcase///
 end////

 
 start_multiplier:
 begin//// start the operation of multiplier
 output_STB_to_multiplier <= 1;//Give input STB to multiplier indicating that you are giving valid input to multiplier.
 source_1_reg <= source_1_temp;//Give 1st input value to multiplier
 source_2_reg <= source_2_temp;//Give 2nd input value to multiplier
 if (output_STB_to_multiplier && !(multiplier_is_BUSY)) begin// We know based on multiplier specification that when 
 //(((input_STB) && (!output_BUSY)) == 1) of multiplier, transaction takes place either input tx or output tx 
 //i.e., if this condition matches we know multiplier has accepted given inputs to it
 output_STB_to_multiplier <= 0;//After transaction occurs no more valid input is there, so make input STB to multiplier = 0
 BUSY_to_multiplier <= 0; //Give input BUSY to multiplier as 0 so that multiplier gets to know that it's receiver i.e., controller is not busy
 mult_cnt_state <= wait_for_multiplier_complete;//Go to next state of waiting for multiplier operation completion
 end//
 end////
 
 
 wait_for_multiplier_complete:
 begin//// Wait or make sure multiplier operation is complete
 if (!(BUSY_to_multiplier) && (input_STB_to_controller)) begin///When output STB of Multiplier becomes high, we know that valid output is ready 
 //and we check the BUSY given by controller to multiplier, 
 //if it is 0 then we latch output of multiplier, 
 //We know based on multiplier specification that when (((input_STB) && (!output_BUSY)) == 1) of multiplier, then transaction takes place, either input tx or output tx, 
 //In this case it is output transaction of multiplier to controller
 BUSY_to_multiplier <= 1; //We turn the input BUSY to multiplier by controller/Receiver as 1 indicating that controller is now BUSY 
 destination_reg <= output_mult;//We latch the output mult as given by multiplier 
 mult_cnt_state <= write_back_to_register;//Go to next state of writing result to register file
 end///
 end////
 
 

 write_back_to_register:
 begin//// Write resultant value to register file
 destination_temp <= destination_reg;// Output Value to be written to register file 
 rd_temp <= rd_reg;// Give destination address to register file
 write_enable_temp <= 1;// Turn write enable on for writing value to register file
 mult_cnt_state <= wait_one_cycle;//Go to next state of waiting one cycle. 
 //Why wait one cycle? because once you give write_enable write will not take place immediately because it is sampled by register file on positive edge of clock.
 end////
 
 
 
 wait_one_cycle:
 begin////Wait one cycle for write to register file to get completed
 mult_cnt_state <= increment_pc_and_update_status;//Go to next state of incrementing PC value and updating status signals for instruction decode controller
 end////
 
 
 
 increment_pc_and_update_status:
 begin//// Increment PC value and update status signals for instruction decode controller
   pc_new_temp <= pc_new_reg + 1;//It's not a jump operation so PC value will be PC+1
   busy_temp <= 0; //Controller no more busy
   done_temp <= 1; //Controller has completed it's operation
   mult_cnt_state <= give_address_to_register_file;//Go back to initial stage
 end
   
 endcase
 
 end//always

 
 
 
 
 
 always@(posedge clk)begin///
 if (rst) begin// In case of reset initialise these values to 0 and make rest all values are automatically don't care
 busy_temp <= 0; //Initialise status signal busy to 0
 done_temp <= 0; //Initialise status signal done to 0
 output_STB_to_multiplier <= 0; //Give input STB to multiplier as 0 because no inputs are ready/valid, they are in don't care states
 write_enable_temp <= 0;//Make sure no writing to register file happens
 mult_cnt_state <= give_address_to_register_file; //Go to initial state and wait for start by instruction decode controller 
 end//
 end///always
 
 endmodule
  
  
         
      
  
 


  
  
         
      
  
  
