

//________IEEE Floating Point Multiplier (Single Precision)________//


/////////////////////////////________Block Diagram________////////////////////////////////////////////////////////////////////////////////////////////



//                        +------------------------+
//          input_a     =>|                        |=> output_mult
//          input_b     =>|                        |
//                        |      multiplier        |=> mult_output_STB
//      mult_input_STB  =>|                        |<= output_module_BUSY
//           mult_BUSY  <=|                        |
//                        +--------^-|-------------+
//                clk______________| |
//              rst__________________|



/////////////////////////////________Specification________////////////////////////////////////////////////////////////////////////////////////////////

//1. A transaction takes place any time the input STB line (mult_input_STB) is true and the output BUSY line (mult_BUSY) is false.
//2. Adder needs to be careful not to ever lower the output BUSY line (mult_BUSY), unless it is ready to receive data.
//3. The input STB (mult_input_STB) line should be raised any time input data is ready for sending. The data source must not wait for multiplier BUSY (mult_BUSY) to be false before raising the input STB line (mult_input_STB).
//4. Busy should be IDLE or 0 (mult_BUSY) when multiplier is not busy.
//5. Once input STB (mult_input_STB) is raised, the data being transferred cannot be changed until the clock after the transaction takes place.
//6. The Data lines (output_mult) hold the previous valid output any time output STB (mult_output_STB) is false.
//7. At Reset output mult_BUSY=0, output mult_output_STB=0, and output data lines will be in don't care.


/////////////////////////////________Port_____List________/////////////////////////////////////////////////////////////////////////////////////////////


//       +__________________________________________________________________________________________________________________________________________________________+
//       |#Port Name           | #Direction  | #Width   |  #Description                                                                                             |
//       |_____________________|_____________|__________|___________________________________________________________________________________________________________|
//       |  input_a            |     input   |     32   |  Input operand a                                                                                          |
//       |  input_b            |     input   |     32   |  Input operand b                                                                                          |
//       |  mult_input_STB     |     input   |     1    |  Input valid signal, indicates input is valid                                                             |
//       |  mult_BUSY          |     output  |     1    |  Output busy signal, indicates multiplier is busy and cannot process next input until current one is done |
//       |  clk                |     input   |     1    |  Clock sample                                                                                             |
//       |  rst                |     input   |     1    |  Active high reset                                                                                        |
//       |  output_mult        |     output  |     32   |  Output multiplication result                                                                             |
//       |  mult_output_STB    |     output  |     1    |  Output valid signal, indicates output is valid                                                           |
//       |  output_module_BUSY |     input   |     1    |  Input busy signal, indicates output module is busy, cannot take next input                               |
//       |_____________________|_____________|__________|___________________________________________________________________________________________________________| 

module multiplier(
        input_a,
        input_b,
        mult_input_STB,
        mult_BUSY,
        clk,
        rst,
        output_mult,
        mult_output_STB,
        output_module_BUSY
		);

  input     clk;
  input     rst;

  input     [31:0] input_a;
  input     [31:0] input_b;
  
  input     mult_input_STB;
  output    mult_BUSY;

  output    [31:0] output_mult;
  output    mult_output_STB;
  input     output_module_BUSY;

  //Intermediate registers
  reg       mult_output_STB_reg;
  reg       [31:0] output_mult_reg;
  reg       mult_BUSY_reg;

  reg       [3:0] state;
  parameter get_a_and_b   = 4'd0,
            unpack        = 4'd1,
            special_cases = 4'd2,
            normalise_a   = 4'd3,
            normalise_b   = 4'd4,
            multiply_0    = 4'd5,
            multiply_1    = 4'd6,
            normalise_1   = 4'd7,
            normalise_2   = 4'd8,
            round         = 4'd9,
            pack          = 4'd10,
            put_z         = 4'd11;

  reg       [31:0] a, b, z;
  reg       [23:0] a_m, b_m, z_m;
  reg       [9:0] a_e, b_e, z_e;
  reg       a_s, b_s, z_s;
  reg       guard, round_bit, sticky;
  reg       [49:0] product;

  always @(posedge clk)
  begin

    case(state)

	  
	  get_a_and_b: //Initial state wait for valid inputs and make BUSY = 0 because it has finished previous operation 
      begin
        mult_BUSY_reg <= 0;
        if (!(mult_BUSY_reg) && mult_input_STB) begin  //Once it gets valid input take that input and start processing.
          a <= input_a;
		  b <= input_b;
          mult_BUSY_reg <= 1; //Turn the BUSY signal on, BUSY = 1 because now it will be busy processing latched inputs and can no more take inputs even if it is valid. 
          state <= unpack;
        end
      end

      unpack:
      begin
        a_m <= a[22 : 0];
        b_m <= b[22 : 0];
        a_e <= a[30 : 23] - 127;
        b_e <= b[30 : 23] - 127;
        a_s <= a[31];
        b_s <= b[31];
        state <= special_cases;
      end

      special_cases:
      begin
        //if a is NaN or b is NaN return NaN 
        if ((a_e == 128 && a_m != 0) || (b_e == 128 && b_m != 0)) begin
          z[31] <= 1;
          z[30:23] <= 255;
          z[22] <= 1;
          z[21:0] <= 0;
          state <= put_z;
        //if a is inf return inf
        end else if (a_e == 128) begin
          z[31] <= a_s ^ b_s;
          z[30:23] <= 255;
          z[22:0] <= 0;
          //if b is zero return NaN
          if (($signed(b_e) == -127) && (b_m == 0)) begin
            z[31] <= 1;
            z[30:23] <= 255;
            z[22] <= 1;
            z[21:0] <= 0;
          end
          state <= put_z;
        //if b is inf return inf
        end else if (b_e == 128) begin
          z[31] <= a_s ^ b_s;
          z[30:23] <= 255;
          z[22:0] <= 0;
          //if a is zero return NaN
          if (($signed(a_e) == -127) && (a_m == 0)) begin
            z[31] <= 1;
            z[30:23] <= 255;
            z[22] <= 1;
            z[21:0] <= 0;
          end
          state <= put_z;
        //if a is zero return zero
        end else if (($signed(a_e) == -127) && (a_m == 0)) begin
          z[31] <= a_s ^ b_s;
          z[30:23] <= 0;
          z[22:0] <= 0;
          state <= put_z;
        //if b is zero return zero
        end else if (($signed(b_e) == -127) && (b_m == 0)) begin
          z[31] <= a_s ^ b_s;
          z[30:23] <= 0;
          z[22:0] <= 0;
          state <= put_z;
        end else begin
          //Denormalised Number
          if ($signed(a_e) == -127) begin
            a_e <= -126;
          end else begin
            a_m[23] <= 1;
          end
          //Denormalised Number
          if ($signed(b_e) == -127) begin
            b_e <= -126;
          end else begin
            b_m[23] <= 1;
          end
          state <= normalise_a;
        end
      end

      normalise_a:
      begin
        if (a_m[23]) begin
          state <= normalise_b;
        end else begin
          a_m <= a_m << 1;
          a_e <= a_e - 1;
        end
      end

      normalise_b:
      begin
        if (b_m[23]) begin
          state <= multiply_0;
        end else begin
          b_m <= b_m << 1;
          b_e <= b_e - 1;
        end
      end

      multiply_0:
      begin
        z_s <= a_s ^ b_s;
        z_e <= a_e + b_e + 1;
        product <= a_m * b_m * 4;
        state <= multiply_1;
      end

      multiply_1:
      begin
        z_m <= product[49:26];
        guard <= product[25];
        round_bit <= product[24];
        sticky <= (product[23:0] != 0);
        state <= normalise_1;
      end

      normalise_1:
      begin
        if (z_m[23] == 0) begin
          z_e <= z_e - 1;
          z_m <= z_m << 1;
          z_m[0] <= guard;
          guard <= round_bit;
          round_bit <= 0;
        end else begin
          state <= normalise_2;
        end
      end

      normalise_2:
      begin
        if ($signed(z_e) < -126) begin
          z_e <= z_e + 1;
          z_m <= z_m >> 1;
          guard <= z_m[0];
          round_bit <= guard;
          sticky <= sticky | round_bit;
        end else begin
          state <= round;
        end
      end

      round:
      begin
        if (guard && (round_bit | sticky | z_m[0])) begin
          z_m <= z_m + 1;
          if (z_m == 24'hffffff) begin
            z_e <=z_e + 1;
          end
        end
        state <= pack;
      end

      pack:
      begin
        z[22 : 0] <= z_m[22:0];
        z[30 : 23] <= z_e[7:0] + 127;
        z[31] <= z_s;
        if ($signed(z_e) == -126 && z_m[23] == 0) begin
          z[30 : 23] <= 0;
        end
        //if overflow occurs, return inf
        if ($signed(z_e) > 127) begin
          z[22 : 0] <= 0;
          z[30 : 23] <= 255;
          z[31] <= z_s;
        end
        state <= put_z;
      end
	  
	  put_z: //Final state valid output is ready , make the output STB/VALID = 1, put valid output.
      begin
        mult_output_STB_reg <= 1;
        output_mult_reg <= z;
        if (mult_output_STB_reg && !(output_module_BUSY)) begin //Once output module is no more BUSY it lowers it's busy signal and output is then taken by next module.
          mult_output_STB_reg <= 0; //Output is no more valid.
          state <= get_a_and_b; //Go back to initial state.
        end
      end

    endcase

	
	 if (rst == 1) begin //At Active high reset, module is no more BUSY, go to initial state and wait for valid inputs. Input is don't care and output is don't care , so output VALID/STB = 0.
      state <= get_a_and_b;
      mult_BUSY_reg <= 0; 
      mult_output_STB_reg <= 0;
    end

  end
  
  
   `ifdef SYNTHESIS_OFF //Purely combinational logic for debugging purpose, based on hexadecimal encoded states it will show named states in waveform 
   //see this register "statename" in ASCII in dump
  reg [8*13:0] statename;//Highest 13 Number of ASCII letters each 8 bits.
  always@* begin
    case (1'b1)
      (state === get_a_and_b)  : statename = "GET_A_AND_B";
      (state === unpack)       : statename = "UNPACK";
      (state === special_cases): statename = "SPECIAL_CASES";//13 ASCII letters
      (state === normalise_a)  : statename = "NORMALISE_A";
      (state === normalise_b)  : statename = "NORMALISE_B";
      (state === multiply_0)   : statename = "MULTIPLY_0";
      (state === multiply_1)   : statename = "MULTIPLY_1";
      (state === normalise_1)  : statename = "NORMALIZE_1";
      (state === normalise_2)  : statename = "NORMALIZE_2";
      (state === round)        : statename = "ROUND";
      (state === pack)         : statename = "PACK";
	  (state === put_z)        : statename = "PUT_Z";
    endcase
  end//always
  `endif
  
  

  //Continuous assignments
  
  assign mult_BUSY = mult_BUSY_reg;
  assign mult_output_STB = mult_output_STB_reg;
  assign output_mult = output_mult_reg;

endmodule
