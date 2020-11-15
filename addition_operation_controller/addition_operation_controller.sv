// Code your design here
`include "reg_file.v"
module add_controller //Does add_register or add_immediate operations
  (clk, rst, start, pc, next_pc, fetch_stage_enable , done, busy, operation_type, source_1_address, source_2_address, destination_address, source_immediate_value, rs1, rs2, rd, source_1_value, source_2_value, destination_value, write_enable);
input clk;//clock
input rst;//reset
input start;//operation start signal
input [1:0] operation_type; //R or I type
input[4:0] pc; //Current pc value  
output[4:0] next_pc; //Next pc value
output busy; //Indicates that operation is going on
output done; //Indicates that operation of controller is done
output fetch_stage_enable; //Enable status register for next instruction
input [4:0] source_1_address; //Rs1 source address 1 , will go to this address and fetch operand_1, this is given to controller
input [4:0] source_2_address; //Rs2 source address 2, will go to this address and fetch operand_2, this is given to controller
input [4:0] destination_address; //Rd destination address, will go to this address and write the resultant value;

output [4:0] rs1 , rs2, rd; //This is the output address to be given to register file
input [31:0] source_immediate_value;//Immediate value directly taken in case of immediate operation


input [31:0] source_1_value;//Value that will be given by register file
input [31:0] source_2_value;//Value that will be given by register file

output [31:0] destination_value;//Resultant value that will be written to register file

output write_enable;//Going to register ,if this is on write will happen.

reg output_STB_to_adder; //input STB to adder
reg adder_is_BUSY; //output BUSY status of adder
reg input_STB_to_controller; //STB given by adder to controller indicating valid add result
reg BUSY_to_adder; //Indicating whether controller is busy if it can take valid result of adder or not

reg [31:0] output_sum;
reg [31:0] destination_reg, destination_temp;

reg busy_temp, done_temp; //
reg [31:0] source_1_reg, source_2_reg, source_1_temp, source_2_temp ;
reg [4:0] pc_new_reg, pc_new_temp;

reg [4:0] rs1_reg, rs2_reg , rd_temp;
reg [4:0] rd_reg;

reg write_enable_temp, fetch_stage_enable_temp;

  adder fpu_add_inst (.input_a(source_1_reg), 
                      .input_b(source_2_reg), 
                      .adder_input_STB(output_STB_to_adder), 
                      .adder_BUSY(adder_is_BUSY), 
                      .clk(clk), 
                      .rst(rst), 
                      .output_sum(output_sum), 
                      .adder_output_STB(input_STB_to_controller) , 
                      .output_module_BUSY(BUSY_to_adder)
                      ); 

reg [3:0] state;
 
assign rs1 = rs1_reg;
assign rs2 = rs2_reg;
assign rd = rd_temp;
assign write_enable = write_enable_temp;
assign next_pc = pc_new_temp;
assign busy = busy_temp;
assign done = done_temp;
assign destination_value = destination_temp;
assign fetch_stage_enable = fetch_stage_enable_temp;

parameter R=2'd0,
          I=2'd1;

parameter give_address_to_register_file=3'd0,
          latch_inputs=3'd1,
          start_adder=3'd2,
          wait_for_adder_complete=3'd3,
          write_back_to_register=3'd4,
          wait_one_cycle=3'd5,
          increment_pc_and_update_status=3'd6;

always @(posedge clk)begin//always
 case (state)
 give_address_to_register_file:begin//Give address to register file
   if(start)begin //If start then only do something and transition to next state otherwise remain in the same state
   write_enable_temp <= 0; //No writing to register file in this stage.
   busy_temp <= 1; //make busy signal high
   done_temp <= 0;//make done signal as 0 because controller just started
   fetch_stage_enable_temp <= 0; //don't enable fetch stage as of now
   pc_new_reg <= pc; //latch current pc value
   rs1_reg <= source_1_address; //Give source address 1 to register file
   rs2_reg <= source_2_address; //Give source address 2 to register file
   rd_reg <= destination_address; //Give destination address to register file
   state <= latch_inputs; //Go to next state
   end
   else begin
   state <= give_address_to_register_file; //if not start wait in the same state
   write_enable_temp <= 0;//No writing to register file because write will occur or previous write has been done.
   busy_temp <= 0; //make busy signal low
   fetch_stage_enable_temp <= 0; //don't enable fetch stage
   end
 end//
 
 latch_inputs:begin//// 
 source_1_temp <= source_1_value; // Latch value of source_1 operand as given by address rs1 by register file
 state <= start_adder;//Go to next state of starting the adder
 case(operation_type)// For selecting source_2 operand either take register value as given by rs2 address by register file or take immediate value based on operation_type flag 
 R:
 begin
 source_2_temp <= source_2_value;
 end
 I:
 begin
 source_2_temp <= source_immediate_value;
 end
 endcase///
 
 end////

 start_adder:begin//// start the operation of adder
 output_STB_to_adder <= 1;//Give input STB to adder indicating valid input
 source_1_reg <= source_1_temp;//Give 1st input value to adder
 source_2_reg <= source_2_temp;//Give 2nd input value to adder
 if (output_STB_to_adder && !(adder_is_BUSY)) begin// We know based on adder specification that when ((STB) && (!BUSY)) of adder transaction takes place.
 output_STB_to_adder <= 0;//After transaction no more valid input , so make input STB to adder = 0.
 BUSY_to_adder <= 0; //Give input BUSY to adder as 0 so that adder gets to know that it's receiver i.e., controller is not busy.
 state <= wait_for_adder_complete;//Go to next state
 end//
 end////
 
 wait_for_adder_complete:begin////
 if (!(BUSY_to_adder) && (input_STB_to_controller)) begin///When output STB of Adder becomes high , we know that valid output is ready and we check the BUSY given by controller , if it is 0 then we latch output of adder. Remember ? when ((STB) && (!BUSY)) of adder then transaction takes place. In this case it is output transaction of adder to controller.
 BUSY_to_adder <= 1; //We turn the input BUSY to adder as 1 indicating that controller is now BUSY. 
 destination_reg <= output_sum;//We latch the output sum  
 state <= write_back_to_register;//Go to next state
 end///
 end////
 
 

 write_back_to_register:begin
 destination_temp <= destination_reg;// Give write value 
 rd_temp <= rd_reg;// Give destination address
 write_enable_temp <= 1;// Turn write enable on
 state <= wait_one_cycle;//Go to next state, Why wait one cycle because once you give write_enable write will not take place immediately because it is based on clock.
 //pc_new_temp <= pc_new_reg+1;
 //busy_temp <= 0;
 //state <= latch_inputs;
 end
 
 wait_one_cycle:begin
 state <= increment_pc_and_update_status; 
 end
 
 increment_pc_and_update_status:begin
   pc_new_temp <= pc_new_reg+1;//It's not a jump operation so PC value will be PC+1.
   busy_temp <= 0; //Controller no more busy
   done_temp <= 1;
   fetch_stage_enable_temp <= 1;//Enable fetch stage
   state <= give_address_to_register_file;//Go back to initial stage
 end
   
 endcase
 
 end//always

 always@(posedge clk)begin
 if (rst) begin// In case of reset initialise these values to 0 and make rest all values are automatically don't care.
 busy_temp <= 0;
 done_temp <= 0;
 fetch_stage_enable_temp <= 0;
 output_STB_to_adder <= 0;
 BUSY_to_adder <= 0;
 write_enable_temp <= 0;//Make sure no writing to reg file happens
 state <= give_address_to_register_file;
 end
 end
 endmodule  



  
  
         
      
  
  