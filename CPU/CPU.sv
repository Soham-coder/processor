`include "../instruction_decode_controller/instruction_decode_controller.sv"
`include "../program_counter/program_counter.sv"

module CPU 
(clk, rst);

input clk;
input rst;


//Poll register
reg fetch_stage_enable;


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

reg [1:0] state;
//States of CPU
parameter fetch_first_instruction = 2'd0,
          fetch_instruction = 2'd1,
          start_instruction_decode_controller = 2'd2;


always@(posedge clk)begin

case(state)

fetch_first_instruction: begin//
program_counter <= 0;
state <= start_instruction_decode_controller;
end//

fetch_instruction: begin//
if(fetch_stage_enable)begin
program_counter <= next_pc_to_cpu;
state <= start_instruction_decode_controller;
end else begin
state<=fetch_instruction; 
end
end//

start_instruction_decode_controller: 
begin// 
instr_in_to_controller <= instr_out_from_pc; 
start_top_controller <= 1;
if(busy)begin
start_top_controller <= 0;
state <= fetch_instruction;
end
end//  

endcase

end//always


always@(posedge clk)begin
if(rst)begin
state <= fetch_first_instruction;
end
end

endmodule