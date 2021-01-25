`include "../defines.vh"

module source_1_value_mux 
(source1_add_cont, source1_mult_cont, source1_muladd_cont, source1_sel, source_1_value);

parameter ADD = 2'b00, MULT = 2'b01, MULADD = 2'b10;

localparam WORD_SIZE = `WORD_SIZE;

output reg [WORD_SIZE - 1:0] source1_add_cont;
output reg [WORD_SIZE - 1:0] source1_mult_cont;
output reg [WORD_SIZE - 1:0] source1_muladd_cont;


input [1:0] source1_sel;

input [WORD_SIZE - 1:0] source_1_value;

always@(source_1_value or source1_sel)begin
case(source1_sel)
ADD:    source1_add_cont    <= source_1_value;
MULT:   source1_mult_cont   <= source_1_value;
MULADD: source1_muladd_cont <= source_1_value;
endcase
end

endmodule 