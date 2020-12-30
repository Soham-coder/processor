module write_enable_mux 
(writeen_add_cont, writeen_mult_cont, writeen_muladd_cont, writeen_sel, write_enable);

parameter ADD = 2'b00, MULT = 2'b01, MULADD = 2'b10;

input  writeen_add_cont;
input  writeen_mult_cont;
input  writeen_muladd_cont;


input [1:0] writeen_sel;

output reg  write_enable;

always@(writeen_add_cont or writeen_mult_cont or writeen_muladd_cont or writeen_sel)begin
case(writeen_sel)
ADD:     write_enable <= writeen_add_cont;
MULT:    write_enable <= writeen_mult_cont;
MULADD:  write_enable <= writeen_muladd_cont;
default: write_enable <= 1'b0;
endcase
end

endmodule