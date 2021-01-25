`include "../defines.vh"
module rs3_mux 
(rs3_muladd_cont, rs3_sel, rs3);

parameter MULADD = 2'b10;
localparam NUMBER_OF_REGISTERS = `NUMBER_OF_REGISTERS;
localparam ADDR_WIDTH = `ADDR_WIDTH ;

input [ADDR_WIDTH - 1:0] rs3_muladd_cont;

input [1:0] rs3_sel;

output reg [ADDR_WIDTH - 1:0] rs3;

always@(rs3_muladd_cont or rs3_sel)begin
case(rs3_sel)
MULADD:  rs3 <= rs3_muladd_cont;
endcase
end

endmodule