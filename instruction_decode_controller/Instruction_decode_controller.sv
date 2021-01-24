
`include "../register_file/reg_file.sv" //It's the same as full code of reg_file coming and sitting in this place
`include "../addition_operation_controller/addition_operation_controller.sv" //It's the same as full code of addition_operation_controller coming and sitting in this place
//Mux includes
`include "../multiplication_operation_controller/multiplication_operation_controller.sv"//It's the same as full code of addition_operation_controller coming and sitting in this place
//Mux includes


//MUX files includes
`include "../rs1_mux/rs1_mux.v" 
`include "../rs2_mux/rs2_mux.v"
`include "../rs3_mux/rs3_mux.v"

`include "../rd_mux/rd_mux.v"
`include "../destination_value_mux/destination_value_mux.v"
`include "../write_enable_mux/write_enable_mux.v"

`include "../source_1_value_mux/source_1_value_mux.v"
`include "../source_2_value_mux/source_2_value_mux.v"
`include "../source_3_value_mux/source_3_value_mux.v"


module instruction_decode_controller
  (clk, rst, start, instruction, busy, done, fetch_stage_enable, next_pc_to_cpu);
  
  input clk;//Clock
  input rst;//Reset signal
  input start;//Start signal given by top level CPU to indicate start the operation
  
  
  input [58:0] instruction; //Instruction given by top level CPU
  
  output busy; //Output busy signal indicating that controller is busy doing current operation
  output done; //Output done signal indicating that controller has finished doing current operation
  output reg fetch_stage_enable; //Output signal to write to poll register which CPU polls to determine when to go for next instruction
  output reg [4:0] next_pc_to_cpu; //Output next pc value to CPU
  
  //Intermediate registers/variables
  reg [4:0] rs1, rs2, rs3, rd;
  reg [4:0] source_1_address_reg, source_2_address_reg, source_3_address_reg, source_1_address, source_2_address, source_3_address;
  reg [31:0] destination_value;
  reg [31:0] source_1_value, source_2_value, source_3_value, source_immediate_value_reg, source_immediate_value;
  reg write_enable;
  
  reg [4:0] pc_reg, pc;
  
  reg [4:0] next_pc_add;
  reg [4:0] next_pc_mult;
  
  reg start_add_controller;
  
  reg start_mult_controller;
  
  //reg fetch_stage_enable_temp;

  reg done_from_add_controller;
  reg busy_from_add_controller;

  reg done_from_mult_controller;
  reg busy_from_mult_controller;

  reg [1:0] operation_type_reg, operation_type;
  reg [4:0] destination_address_reg, destination_address;
  
  reg busy_temp, done_temp;
  
  //Continuous assignment of output signals
  assign busy = busy_temp;
  assign done = done_temp;
  //assign fetch_stage_enable = fetch_stage_enable_temp;
  //assign next_pc_to_cpu = next_pc;
   
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
  
  //Mux ports for add controller
  reg [4:0] rs1_add_cont, rs2_add_cont, rd_add_cont;
  reg [31:0] source1_add_cont, source2_add_cont, source3_add_cont, destval_add_cont;
  reg writeen_add_cont;
  
  //Sub-controller instance
  //Many more instances will be there for  division, comparison etc.,
  //This one does add_register or add_immediate operations
  add_controller  add_cnt_inst
  (
    .clk(clk), 
    .rst(rst),
    .start(start_add_controller), 
    .pc(pc), 
    .next_pc(next_pc_add),  
    .done(done_from_add_controller),
    .busy(busy_from_add_controller), 
    .operation_type(operation_type), 
    .source_1_address(source_1_address), 
    .source_2_address(source_2_address), 
    .destination_address(destination_address), 
    .source_immediate_value(source_immediate_value), 
    .rs1(rs1_add_cont), 
    .rs2(rs2_add_cont), 
    .rd(rd_add_cont), 
    .source_1_value(source1_add_cont), 
    .source_2_value(source2_add_cont), 
    .destination_value(destval_add_cont), 
    .write_enable(writeen_add_cont)
  );

  
  //Mux ports for mult controller
  reg [4:0] rs1_mult_cont, rs2_mult_cont, rd_mult_cont;
  reg [31:0] source1_mult_cont, source2_mult_cont, source3_mult_cont, destval_mult_cont;
  reg writeen_mult_cont;

  //Sub-controller instance
  //Many more instances will be there for division, comparison etc.,
  //This one does mult_register or mult_immediate operations
  mult_controller  mult_cnt_inst
  (
    .clk(clk), 
    .rst(rst),
    .start(start_mult_controller), 
    .pc(pc), 
    .next_pc(next_pc_mult),  
    .done(done_from_mult_controller),
    .busy(busy_from_mult_controller), 
    .operation_type(operation_type), 
    .source_1_address(source_1_address), 
    .source_2_address(source_2_address), 
    .destination_address(destination_address), 
    .source_immediate_value(source_immediate_value), 
    .rs1(rs1_mult_cont), 
    .rs2(rs2_mult_cont), 
    .rd(rd_mult_cont), 
    .source_1_value(source1_mult_cont), 
    .source_2_value(source2_mult_cont), 
    .destination_value(destval_mult_cont), 
    .write_enable(writeen_mult_cont)
  );
  
  //Intermediate registers for RS1 MUX
  reg [4:0] rs1_muladd_cont;
  reg [1:0] rs1_sel;
  
  //RS1 MUX instance
  rs1_mux rs1_mux_inst 
  (
   .rs1_add_cont(rs1_add_cont), 
   .rs1_mult_cont(rs1_mult_cont), 
   .rs1_muladd_cont(rs1_muladd_cont), 
   .rs1_sel(rs1_sel), 
   .rs1(rs1)
  );
  
  //Intermediate registers for RS2 MUX
  reg [4:0] rs2_muladd_cont;
  reg [1:0] rs2_sel;

  //RS2 MUX instance
  rs2_mux rs2_mux_inst 
  (
   .rs2_add_cont(rs2_add_cont), 
   .rs2_mult_cont(rs2_mult_cont), 
   .rs2_muladd_cont(rs2_muladd_cont), 
   .rs2_sel(rs2_sel), 
   .rs2(rs2)
  );
  
  //Intermediate registers for RS3 MUX
  reg [4:0] rs3_muladd_cont;
  reg [1:0] rs3_sel;

  //RS3 MUX instance
  rs3_mux rs3_mux_inst 
  (
   .rs3_muladd_cont(rs3_muladd_cont),
   .rs3_sel(rs3_sel), 
   .rs3(rs3)
  );
  

  //Intermediate registers for RD MUX
  reg [4:0] rd_muladd_cont;
  reg [1:0] rd_sel;

  //RD MUX instance
  rd_mux rd_mux_inst 
  (
   .rd_add_cont(rd_add_cont), 
   .rd_mult_cont(rd_mult_cont), 
   .rd_muladd_cont(rd_muladd_cont), 
   .rd_sel(rd_sel), 
   .rd(rd)
  );
  
  //Intermediate registers for destval MUX
  reg [31:0] destval_muladd_cont;
  reg [1:0] dest_sel;

  //Destination value MUX instance
  destination_value_mux destval_mux_inst 
  (
   .destval_add_cont(destval_add_cont), 
   .destval_mult_cont(destval_mult_cont), 
   .destval_muladd_cont(destval_muladd_cont), 
   .dest_sel(dest_sel), 
   .destination_value(destination_value)
  );

  //Intermediate registers for Writeen val MUX 
  reg writeen_muladd_cont;
  reg [1:0] writeen_sel;

  //Write Enable MUX instance
  write_enable_mux write_en_mux_inst 
  (
   .writeen_add_cont(writeen_add_cont), 
   .writeen_mult_cont(writeen_mult_cont), 
   .writeen_muladd_cont(writeen_muladd_cont), 
   .writeen_sel(writeen_sel), 
   .write_enable(write_enable)
  );
  
  //Intermediate registers for source1 val MUX
  reg [31:0] source1_muladd_cont;
  reg [1:0] source1_sel;

  //Source1 Value MUX instance
  source_1_value_mux source_1_val_mux_inst 
  (
   .source1_add_cont(source1_add_cont), 
   .source1_mult_cont(source1_mult_cont), 
   .source1_muladd_cont(source1_muladd_cont), 
   .source1_sel(source1_sel), 
   .source_1_value(source_1_value)
  );
  
  //Intermediate registers for source2 val MUX
  reg [31:0] source2_muladd_cont;
  reg [1:0] source2_sel;

  //Source2 Value MUX instance
  source_2_value_mux source_2_val_mux_inst 
  (
   .source2_add_cont(source2_add_cont), 
   .source2_mult_cont(source2_mult_cont), 
   .source2_muladd_cont(source2_muladd_cont), 
   .source2_sel(source2_sel), 
   .source_2_value(source_2_value)
  );
  
  //Intermediate registers for source3 val MUX
  reg [31:0] source3_muladd_cont;
  reg [1:0] source3_sel;

  //Source3 Value MUX instance
  source_3_value_mux source_3_val_mux_inst 
  ( 
   .source3_muladd_cont(source3_muladd_cont), 
   .source3_sel(source3_sel), 
   .source_3_value(source_3_value)
  );
  //////////////////////////////////////////////
  
  
  
  reg [2:0] top_cnt_state; //State register to hold current state of controller
  
  //States of controller
  parameter instruction_decode = 3'd0,
            
            start_add_controller_and_sel_mux = 3'd1,
            start_mult_controller_and_sel_mux = 3'd2,
            
            wait_for_add_controller_to_finish = 3'd3,
            wait_for_mult_controller_to_finish = 3'd4;
  
  
  //Parameters for rs1 sel
  parameter RS1_ADD = 2'b00, RS1_MUL = 2'b01, RS1_MULADD = 2'b10;
  //Parameters for rs2 sel
  parameter RS2_ADD = 2'b00, RS2_MUL = 2'b01, RS2_MULADD = 2'b10;
  //Parameters for rd sel
  parameter RD_ADD = 2'b00, RD_MUL = 2'b01, RD_MULADD = 2'b10;
  //Parameters for dest sel
  parameter DEST_ADD = 2'b00, DEST_MUL = 2'b01, DEST_MULADD = 2'b10;
  //Parameters for writeen_sel
  parameter WRITEEN_ADD = 2'b00, WRITEEN_MUL = 2'b01, WRITEEN_MULADD = 2'b10;
  //Parameters for source1_sel
  parameter SOURCE1_ADD = 2'b00, SOURCE1_MUL = 2'b01, SOURCE1_MULADD = 2'b10;
  //Parameters for source2_sel
  parameter SOURCE2_ADD = 2'b00, SOURCE2_MUL = 2'b01, SOURCE2_MULADD = 2'b10;
  
  //Instruction opcode encoding -- instruction[56:52] indicates type of operation like ADD, MULT, DIV, COMP etc., So many more to come 
  parameter ADD = 5'b00000;
  parameter MULT= 5'b00001;
  
  always@(posedge clk)begin//always
    case(top_cnt_state)
      instruction_decode:begin
        if(start)begin //Once CPU gives start signal start the operation of instruction-decode controller
          busy_temp <= 1; //Make the busy signal high, because operation has started for the controller
          done_temp <= 0; //Make the done signal low, because it is currently busy 
          fetch_stage_enable <= 0; //Write 0 to the poll register of CPU
          case(instruction[56:52])//Opcode indicates operation type
            ADD:begin
              operation_type_reg <= instruction[58:57]; //Flag indicates flag of operation e.g., I,J or R-type
              destination_address_reg <= instruction[51:47]; //Destination address indicates the destination register to which resultant value will get written to
              source_1_address_reg <= instruction[46:42]; //Source 1 address indicates the source register address of the first operand
              source_2_address_reg <= instruction[41:37]; //Source 2 address indicates the source register address of the second operand
              pc_reg <= instruction[36:32]; //Indicates the current PC value
              source_immediate_value_reg <= instruction[31:0]; //Immediate 32 bit value or operand in case of immediate operation
              ///Start the add controller
              top_cnt_state <= start_add_controller_and_sel_mux; //Next state of starting the add operation controller
            end
            MULT:begin
              operation_type_reg <= instruction[58:57]; //Flag indicates flag of operation e.g., I,J or R-type
              destination_address_reg <= instruction[51:47]; //Destination address indicates the destination register to which resultant value will get written to
              source_1_address_reg <= instruction[46:42]; //Source 1 address indicates the source register address of the first operand
              source_2_address_reg <= instruction[41:37]; //Source 2 address indicates the source register address of the second operand
              pc_reg <= instruction[36:32]; //Indicates the current PC value
              source_immediate_value_reg <= instruction[31:0]; //Immediate 32 bit value or operand in case of immediate operation
              ///Start the mult controller
              top_cnt_state <= start_mult_controller_and_sel_mux; //Next state of starting the mult operation controller
            end 
          endcase
        end//if
        else begin
          busy_temp <= 0; //In case CPU don't give start signal make the busy signal low
          top_cnt_state<= instruction_decode; //In case no start signal remain in same state
        end
      end
      
      start_add_controller_and_sel_mux:begin
        start_add_controller <= 1; //start the add operation controller
        operation_type <= operation_type_reg; //Get the flag
        pc <= pc_reg; //Get the current PC value
        source_1_address <= source_1_address_reg; //Get the current source 1 address
        source_2_address <= source_2_address_reg; //Get the current source 2 address
        destination_address <= destination_address_reg; //Get the destination address
        source_immediate_value <= source_immediate_value_reg; //Get the 32 bit source immediate value
        //
         //Give inputs to Mux sel
			  rs1_sel <= RS1_ADD;
        rs2_sel <= RS2_ADD;
        rd_sel  <= RD_ADD;
        dest_sel <= DEST_ADD;
        writeen_sel <= WRITEEN_ADD;
        source1_sel <= SOURCE1_ADD;
        source2_sel <= SOURCE2_ADD;
           //
        if (busy_from_add_controller) begin //Once gets busy from sub-controller or add-operation controller make the start signal of sub-controller as 0
          
          start_add_controller <= 0; //Make the start signal of sub-controller as 0
          top_cnt_state <= wait_for_add_controller_to_finish; //Go to the next state of waiting for sub-controller to finish operation
        end
        end

      start_mult_controller_and_sel_mux:begin
        start_mult_controller <= 1; //start the mult operation controller
        operation_type <= operation_type_reg; //Get the flag
        pc <= pc_reg; //Get the current PC value
        source_1_address <= source_1_address_reg; //Get the current source 1 address
        source_2_address <= source_2_address_reg; //Get the current source 2 address
        destination_address <= destination_address_reg; //Get the destination address
        source_immediate_value <= source_immediate_value_reg; //Get the 32 bit source immediate value
        //
         //Give inputs to Mux sel
			  rs1_sel <= RS1_MUL;
        rs2_sel <= RS2_MUL;
        rd_sel  <= RD_MUL;
        dest_sel <= DEST_MUL;
        writeen_sel <= WRITEEN_MUL;
        source1_sel <= SOURCE1_MUL;
        source2_sel <= SOURCE2_MUL;
           //
        if (busy_from_mult_controller) begin //Once gets busy from sub-controller or mult-operation controller make the start signal of sub-controller as 0
          
          start_mult_controller <= 0; //Make the start signal of sub-controller as 0
          top_cnt_state <= wait_for_mult_controller_to_finish; //Go to the next state of waiting for sub-controller to finish operation
        end
      end
  
       wait_for_add_controller_to_finish:begin //Wait for sub-controller to finish operation
         if(done_from_add_controller && !(busy_from_add_controller))begin //Once sub-controller gives done as 1 and it is no more busy
     //indicates that operation of sub-controller is finished. So go to next state of making busy signal 0 and done signal 1 of current controller
           busy_temp <= 0; //Make busy signal 0
           done_temp <= 1; //Make done signal 1
           next_pc_to_cpu <= next_pc_add; //Update PC value
           fetch_stage_enable <= 1; //Write 1 to the poll register of CPU
           top_cnt_state <= instruction_decode; //Return to the first state of instruction decode
         end
       end

        wait_for_mult_controller_to_finish:begin //Wait for sub-controller to finish operation
         if(done_from_mult_controller && !(busy_from_mult_controller))begin //Once sub-controller gives done as 1 and it is no more busy
     //indicates that operation of sub-controller is finished. So go to next state of making busy signal 0 and done signal 1 of current controller
           busy_temp <= 0; //Make busy signal 0
           done_temp <= 1; //Make done signal 1
           next_pc_to_cpu <= next_pc_mult; //Update PC value
           fetch_stage_enable <= 1; //Write 1 to the poll register of CPU
           top_cnt_state <= instruction_decode; //Return to the first state of instruction decode
         end
       end

    endcase
  end//always
  
  always@(posedge clk)begin
 if (rst) begin// In case of reset initialise these values to 0 and make rest all values are automatically don't care.
 busy_temp <= 0; //Make busy signal 0
 done_temp <= 0; //Make done signal 0
 top_cnt_state <= instruction_decode; //Go to the first state of instruction decode
 end
 end
endmodule

