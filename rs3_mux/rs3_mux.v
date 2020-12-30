module rs3_mux 
(rs3_muladd_cont, rs3_sel, rs3);

parameter MULADD = 2'b10;

input [4:0] rs3_muladd_cont;

input [1:0] rs3_sel;

output reg [4:0] rs3;

always@(rs3_muladd_cont or rs3_sel)begin
case(rs3_sel)
MULADD:  rs3 <= rs3_muladd_cont;
default: rs3 <= 5'bx;
endcase
end

endmodule