/**
  * Register File module
  *
  * Output Ports:
  *   - ReadData1: 32 bit registered output
  *   - ReadData2: 32 bit registered output
  * 
  * Note- If Read Addresses i.e., if ReadReg1/ReadReg2 = 0 then Read Data will always be 0.
  * 
  * Input ports:
  * 	- ReadReg1:  5-Bit address to select a register to be read
  *		- ReadReg2:  5-Bit address to select a register to be read
  *		- WriteReg:  5-Bit address to select a register to be written
  *		- WriteData: 32-Bit write input port
  *		- RegWrite:  1-Bit control input signal
  *
  */

module RegisterFile(ReadData1, ReadData2, ReadReg1, ReadReg2, WriteReg, WriteData, RegWrite, clk);

  output reg[31:0] ReadData1, ReadData2;
  input wire [4:0] ReadReg1, ReadReg2, WriteReg;
  input wire [31:0] WriteData;
  input wire RegWrite, clk;

  reg [31:0] Registers[31:0];

  always @ ( ReadReg1, ReadReg2 )
  begin
    ReadData1 <= (ReadReg1 == 0)? 32'b0 : Registers[ReadReg1];
    ReadData2 <= (ReadReg2 == 0)? 32'b0 : Registers[ReadReg2];
  end

  always @ ( posedge clk )
  begin
    if(RegWrite)
      begin
        Registers[WriteReg] <= WriteData;
      end
  end

endmodule