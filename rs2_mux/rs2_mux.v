`include "../defines.vh"
module rs2_mux 
(rs2_add_cont, rs2_mult_cont, rs2_muladd_cont, rs2_sel, rs2);

parameter ADD = 2'b00, MULT = 2'b01, MULADD = 2'b10;
localparam NUMBER_OF_REGISTERS = `NUMBER_OF_REGISTERS;
localparam ADDR_WIDTH = `ADDR_WIDTH ;

input [ADDR_WIDTH - 1:0] rs2_add_cont;
input [ADDR_WIDTH - 1:0] rs2_mult_cont;
input [ADDR_WIDTH - 1:0] rs2_muladd_cont;
input [1:0] rs2_sel;

output reg [ADDR_WIDTH - 1:0] rs2;

always@(rs2_add_cont or rs2_mult_cont or rs2_muladd_cont or rs2_sel)begin
case(rs2_sel)
ADD:    rs2 <= rs2_add_cont;
MULT:   rs2 <= rs2_mult_cont;
MULADD: rs2 <= rs2_muladd_cont;
endcase
end

endmodule