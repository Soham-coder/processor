module rs1_mux 
(rs1_add_cont, rs1_mult_cont, rs1_muladd_cont, rs1_sel, rs1);

parameter ADD = 2'b00, MULT = 2'b01, MULADD = 2'b10;

input [4:0] rs1_add_cont;
input [4:0] rs1_mult_cont;
input [4:0] rs1_muladd_cont;
input [1:0] rs1_sel;

output reg [4:0] rs1;

always@(rs1_add_cont or rs1_mult_cont or rs1_muladd_cont, rs1_sel)begin
case(rs1_sel)
ADD:   rs1 <= rs1_add_cont;
MULT:  rs1 <= rs1_mult_cont;
MULADD:rs1 <= rs1_muladd_cont;
endcase
end

endmodule