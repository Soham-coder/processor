`include "../instruction_decode_controller/instruction_decode_controller.sv"
`include "../program_counter/program_counter.sv"

module CPU 
(clk, rst);

input clk; //Input clk
input rst; //Input rst


//Poll register
reg fetch_stage_enable; //Poll register which is updated or written by instruction_decode_controller(top level controller)


//Intermediate registers
reg [4:0] next_pc_to_cpu;
reg [4:0] program_counter;
reg [58:0] instr_in_to_controller, instr_out_from_pc;
reg start_top_controller;

reg busy,done;

//Top controller instance//
instruction_decode_controller top_cont_inst
	(.clk(clk), 
	 .rst(rst), 
	 .start(start_top_controller), 
	 .instruction(instr_in_to_controller), 
	 .busy(busy), 
	 .done(done), 
	 .fetch_stage_enable(fetch_stage_enable), 
	 .next_pc_to_cpu(next_pc_to_cpu)
	 );

//Program counter instance//
program_counter pc_inst
	(.pc_address(program_counter),
	 .dout(instr_out_from_pc)
	 );	 

reg [1:0] cpu_state;
//States of CPU
parameter fetch_first_instruction = 2'd0,
          fetch_instruction = 2'd1,
          start_instruction_decode_controller = 2'd2;


always@(posedge clk)begin

case(cpu_state)

fetch_first_instruction: begin// In case of rst signal go to state- fetch_first_instruction
program_counter <= 0; // Give address 0 to program counter i.e., fetch first instruction
cpu_state <= start_instruction_decode_controller; // Go to state of starting the top level instruction decode controller
end//

fetch_instruction: begin // Go to the state of fetch next instruction after 1st instruction is complete
if(fetch_stage_enable)begin // Poll the register "fetch_stage_enable" --> In case it is 1, it indicates that previous instruction is completed by sub-controller+top-controller 
// and we need to fetch next instruction 
program_counter <= next_pc_to_cpu;// Give the next pc value/address to program counter as given by sub-controller
cpu_state <= start_instruction_decode_controller; // Start the top level instruction decode controller
end else begin
cpu_state<=fetch_instruction; // If "fetch_stage_enable" register is 0, remain in the same state
end
end//

start_instruction_decode_controller: 
begin// 
instr_in_to_controller <= instr_out_from_pc; // Give the next instruction to the controller as given by program counter
start_top_controller <= 1; // Start the top level instruction_decode_controller
if(busy)begin // If top level instruction_decode_controller have become busy turn off the controller
start_top_controller <= 0; // Turn off the controller i.e., make the start signal of controller as 0
cpu_state <= fetch_instruction; // Go to the state of fetching next instruction
end
end//  

endcase

end//always


always@(posedge clk)begin
if(rst)begin
cpu_state <= fetch_first_instruction; // If rst is high , go to the state of fetch_first_instruction i.e., fetch the first instruction
end
end

endmodule
