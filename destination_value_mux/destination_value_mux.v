`include "../defines.vh"
module destination_value_mux 
(destval_add_cont, destval_mult_cont, destval_muladd_cont, dest_sel, destination_value);


localparam  WORD_SIZE = `WORD_SIZE;


parameter ADD = 2'b00, MULT = 2'b01, MULADD = 2'b10;

input [WORD_SIZE - 1:0] destval_add_cont;
input [WORD_SIZE - 1:0] destval_mult_cont;
input [WORD_SIZE - 1:0] destval_muladd_cont;


input [1:0] dest_sel;

output reg [WORD_SIZE - 1:0] destination_value;

always@(destval_add_cont or destval_mult_cont or destval_muladd_cont or dest_sel)begin
case(dest_sel)
ADD:    destination_value <= destval_add_cont;
MULT:   destination_value <= destval_mult_cont;
MULADD: destination_value <= destval_muladd_cont;
endcase
end

endmodule