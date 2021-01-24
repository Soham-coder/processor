module source_3_value_mux 
(source3_muladd_cont, source3_sel, source_3_value);

parameter  MULADD = 2'b10;

//output reg [31:0] source3_add_cont;
//output reg [31:0] source3_mult_cont;
output reg [31:0] source3_muladd_cont;


input [1:0] source3_sel;

input [31:0] source_3_value;

always@(source_3_value or source3_sel)begin
case(source3_sel)
//ADD:    source3_add_cont    <= source_3_value;
//MULT:   source3_mult_cont   <= source_3_value;
MULADD: source3_muladd_cont <= source_3_value;
endcase
end

endmodule 