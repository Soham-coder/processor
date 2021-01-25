/**
  * Register File module
  *
  * Output Ports:
  *   - ReadData1: 32 bit registered output
  *   - ReadData2: 32 bit registered output
  *   - ReadData3: 32 bit registered output
  * 
  * Note- If Read Addresses i.e., if ReadReg1/ReadReg2/ReadReg3 = 0 then Read Data will always be 0.
  * 
  * Input ports:
  * 	- ReadReg1:  5-Bit address to select a register to be read
  *		- ReadReg2:  5-Bit address to select a register to be read
  *   - ReadReg3:  5-Bit address to select a register to be read
  *		- WriteReg:  5-Bit address to select a register to be written
  *		- WriteData: 32-Bit write input port
  *		- RegWrite:  1-Bit control input signal
  *
  */
`include "../defines.vh"
module RegisterFile(ReadData1, ReadData2, ReadData3, ReadReg1, ReadReg2, ReadReg3, WriteReg, WriteData, RegWrite, clk);
  
  parameter WORD_SIZE = `WORD_SIZE;
  parameter NUMBER_OF_REGISTERS = `NUMBER_OF_REGISTERS;
  parameter ADDR_WIDTH = $clog2(NUMBER_OF_REGISTERS);
  
  output reg [WORD_SIZE-1:0] ReadData1, ReadData2, ReadData3;
  input wire [ADDR_WIDTH-1:0] ReadReg1, ReadReg2, ReadReg3, WriteReg;
  input wire [WORD_SIZE-1:0] WriteData;
  input wire RegWrite, clk;

  reg [WORD_SIZE-1:0] Registers[NUMBER_OF_REGISTERS - 1:0];

  always @ ( ReadReg1, ReadReg2, ReadReg3 )
  begin
    ReadData1 <= (ReadReg1 == 0)? 32'b0 : Registers[ReadReg1];
    ReadData2 <= (ReadReg2 == 0)? 32'b0 : Registers[ReadReg2];
    ReadData3 <= (ReadReg3 == 0)? 32'b0 : Registers[ReadReg3];
  end

  always @ ( posedge clk )
  begin
    if(RegWrite)
      begin
        Registers[WriteReg] <= WriteData;
      end
  end

endmodule