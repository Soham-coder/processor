
`include "../register_file/reg_file.v" //It's the same as full code of reg_file coming and sitting in this place
`include "../addition_operation_controller/addition_operation_controller.sv" //It's the same as full code of addition_operation_controller coming and sitting in this place



module instruction_decode_controller
  (clk, rst, start, instruction, busy, done, fetch_stage_enable, next_pc_to_cpu);
  
  input clk;//Clock
  input rst;//Reset signal
  input start;//Start signal given by top level CPU to indicate start the operation
  
  
  input [58:0] instruction; //Instruction given by top level CPU
  
  output busy; //Output busy signal indicating that controller is busy doing current operation
  output done; //Output done signal indicating that controller has finished doing current operation
  output fetch_stage_enable; //Output signal to write to poll register which CPU polls to determine when to go for next instruction
  output [4:0] next_pc_to_cpu; //Output next pc value to CPU
  
  //Intermediate registers/variables
  reg [4:0] rs1, rs2, rd;
  reg [4:0] source_1_address_reg, source_2_address_reg, source_1_address, source_2_address;
  reg [31:0] destination_value;
  reg [31:0] source_1_value, source_2_value, source_immediate_value_reg, source_immediate_value;
  reg write_enable;
  
  reg [4:0] pc_reg, pc;
  reg [4:0] next_pc;
  
  reg start_add_controller;
  
  reg fetch_stage_enable_temp;
  reg done_from_add_controller;
  reg busy_from_add_controller;
  reg [1:0] operation_type_reg, operation_type;
  reg [4:0] destination_address_reg, destination_address;
  
  reg busy_temp, done_temp;
  
  //Continuous assignment of output signals
  assign busy = busy_temp;
  assign done = done_temp;
  assign fetch_stage_enable = fetch_stage_enable_temp;
  assign next_pc_to_cpu = next_pc;
   
   //Register file instance 
   //Off-course only one will be there, since it is acting like a shared scratchpad memory
   RegisterFile reg_inst
  (
   .ReadData1(source_1_value), 
   .ReadData2(source_2_value), 
   .ReadReg1(rs1), 
   .ReadReg2(rs2),
   .WriteReg(rd), 
   .WriteData(destination_value), 
   .RegWrite(write_enable), 
   .clk(clk)
  );
  
  //Sub-controller instance
  //Many more instances will be there for multiplication, division, comparison etc.,
  //This one does add_register or add_immediate operations
  add_controller  add_cnt_inst
  (
    .clk(clk), 
    .rst(rst),
    .start(start_add_controller), 
    .pc(pc), 
    .next_pc(next_pc),  
    .done(done_from_add_controller),
    .busy(busy_from_add_controller), 
    .operation_type(operation_type), 
    .source_1_address(source_1_address), 
    .source_2_address(source_2_address), 
    .destination_address(destination_address), 
    .source_immediate_value(source_immediate_value), 
    .rs1(rs1), 
    .rs2(rs2), 
    .rd(rd), 
    .source_1_value(source_1_value), 
    .source_2_value(source_2_value), 
    .destination_value(destination_value), 
    .write_enable(write_enable)
  );
  
  reg [1:0] state; //State register to hold current state of controller
  
  //States of controller
  parameter instruction_decode = 2'd0,
            start_controller = 2'd1,
            wait_for_controller_to_finish = 2'd2;
  
  //Instruction opcode encoding -- instruction[56:52] indicates type of operation like ADD, MULT, DIV, COMP etc., So many more to come 
  parameter ADD = 5'd0;
  
  always@(posedge clk)begin//always
    case(state)
      instruction_decode:begin
        if(start)begin //Once CPU gives start signal start the operation of instruction-decode controller
          busy_temp <= 1; //Make the busy signal high, because operation has started for the controller
          done_temp <= 0; //Make the done signal low, because it is currently busy 
          fetch_stage_enable_temp <= 0; //Write 0 to the poll register of CPU
          case(instruction[56:52])//Opcode indicates operation type
            ADD:begin
              operation_type_reg <= instruction[58:57]; //Flag indicates flag of operation e.g., I,J or R-type
              destination_address_reg <= instruction[51:47]; //Destination address indicates the destination register to which resultant value will get written to
              source_1_address_reg <= instruction[46:42]; //Source 1 address indicates the source register address of the first operand
              source_2_address_reg <= instruction[41:37]; //Source 2 address indicates the source register address of the second operand
              pc_reg <= instruction[36:32]; //Indicates the current PC value
              source_immediate_value_reg <= instruction[31:0]; //Immediate 32 bit value or operand in case of immediate operation
              state <= start_controller; //Next state of starting the add operation controller
            end  
          endcase
        end//if
        else begin
          busy_temp <= 0; //In case CPU don't give start signal make the busy signal low
          state<= instruction_decode; //In case no start signal remain in same state
        end
      end
      
      start_controller:begin
        start_add_controller <= 1; //start the add operation controller
        operation_type <= operation_type_reg; //Get the flag
        pc <= pc_reg; //Get the current PC value
        source_1_address <= source_1_address_reg; //Get the current source 1 address
        source_2_address <= source_2_address_reg; //Get the current source 2 address
        destination_address <= destination_address_reg; //Get the destination address
        source_immediate_value <= source_immediate_value_reg; //Get the 32 bit source immediate value
        if (busy_from_add_controller) begin //Once gets busy from sub-controller or add-operation controller make the start signal of sub-controller as 0
          start_add_controller <= 0; //Make the start signal of sub-controller as 0
          state <= wait_for_controller_to_finish; //Go to the next state of waiting for sub-controller to finish operation
        end
        end
  
       wait_for_controller_to_finish:begin //Wait for sub-controller to finish operation
         if(done_from_add_controller && !(busy_from_add_controller))begin //Once sub-controller gives done as 1 and it is no more busy
     //indicates that operation of sub-controller is finished. So go to next state of making busy signal 0 and done signal 1 of current controller
           busy_temp <= 0; //Make busy signal 0
           done_temp <= 1; //Make done signal 1
           fetch_stage_enable_temp <= 1; //Write 1 to the poll register of CPU
           state <= instruction_decode; //Return to the first state of instruction decode
         end
       end
    endcase
  end//always
  
  always@(posedge clk)begin
 if (rst) begin// In case of reset initialise these values to 0 and make rest all values are automatically don't care.
 busy_temp <= 0; //Make busy signal 0
 done_temp <= 0; //Make done signal 0
 state <= instruction_decode; //Go to the first state of instruction decode
 end
 end
endmodule