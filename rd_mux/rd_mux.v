module rd_mux 
(rd_add_cont, rd_mult_cont, rd_muladd_cont, rd_sel, rd);

parameter ADD = 2'b00, MULT = 2'b01, MULADD = 2'b10;

input [4:0] rd_add_cont;
input [4:0] rd_mult_cont;
input [4:0] rd_muladd_cont;


input [1:0] rd_sel;

output reg [4:0] rd;

always@(rd_add_cont or rd_mult_cont or rd_muladd_cont or rd_sel)begin
case(rd_sel)
ADD:    rd <= rd_add_cont;
MULT:   rd <= rd_mult_cont;
MULADD: rd <= rd_muladd_cont;
endcase
end

endmodule