`include "../defines.vh"
module source_2_value_mux 
(source2_add_cont, source2_mult_cont, source2_muladd_cont, source2_sel, source_2_value);

parameter ADD = 2'b00, MULT = 2'b01, MULADD = 2'b10;
localparam WORD_SIZE = `WORD_SIZE;

output reg [WORD_SIZE - 1:0] source2_add_cont;
output reg [WORD_SIZE - 1:0] source2_mult_cont;
output reg [WORD_SIZE - 1:0] source2_muladd_cont;


input [1:0] source2_sel;

input [WORD_SIZE - 1:0] source_2_value;

always@(source_2_value or source2_sel)begin
case(source2_sel)
ADD:    source2_add_cont    <= source_2_value;
MULT:   source2_mult_cont   <= source_2_value;
MULADD: source2_muladd_cont <= source_2_value;
endcase
end

endmodule