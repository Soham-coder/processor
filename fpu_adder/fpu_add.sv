

//________IEEE Floating Point Adder (Single Precision)________//


/////////////////////////////________Block Diagram________////////////////////////////////////////////////////////////////////////////////////////////



//                        +-------------------+
//          input_a     =>|                   |=> output_sum
//          input_b     =>|                   |
//                        |      adder        |=> adder_output_STB
//      adder_input_STB =>|                   |<= output_module_BUSY
//           adder_BUSY <=|                   |
//                        +--------^-|--------+
//                clk______________| |
//              rst__________________|



/////////////////////////////________Specification________////////////////////////////////////////////////////////////////////////////////////////////

//1. A transaction takes place any time the input STB line (adder_input_STB) is true and the output BUSY line (adder_BUSY) is false.
//2. Adder needs to be careful not to ever lower the output BUSY line (adder_BUSY), unless it is ready to receive data.
//3. The input STB (adder_input_STB) line should be raised any time input data is ready for sending. The data source must not wait for adder BUSY (adder_BUSY) to be false before raising the input STB line (adder_input_STB).
//4. Busy should be IDLE or 0 (adder_BUSY) when adder is not busy.
//5. Once input STB (adder_input_STB) is raised, the data being transferred cannot be changed until the clock after the transaction takes place.
//6. The Data lines (output_sum) hold the previous valid output any time output STB (adder_output_STB) is false.
//7. At Reset output adder_BUSY=0, output adder_output_STB=0, and output data lines will be in don't care.


/////////////////////////////________Port_____List________/////////////////////////////////////////////////////////////////////////////////////////////


//       +_____________________________________________________________________________________________________________________________________________________+
//       |#Port Name           | #Direction  | #Width   |  #Description                                                                                        |
//       |_____________________|_____________|__________|______________________________________________________________________________________________________|
//       |  input_a            |     input   |     32   |  Input operand a                                                                                     |
//       |  input_b            |     input   |     32   |  Input operand b                                                                                     |
//       |  adder_input_STB    |     input   |     1    |  Input valid signal, indicates input is valid                                                        |
//       |  adder_BUSY         |     output  |     1    |  Output busy signal, indicates adder is busy and cannot process next input until current one is done |
//       |  clk                |     input   |     1    |  Clock sample                                                                                        |
//       |  rst                |     input   |     1    |  Active high reset                                                                                   |
//       |  output_sum         |     output  |     32   |  Output summation result                                                                             |
//       |  adder_output_STB   |     output  |     1    |  Output valid signal, indicates output is valid                                                      |
//       |  output_module_BUSY |     input   |     1    |  Input busy signal, indicates output module is busy, cannot take next input                          |
//       |_____________________|_____________|__________|______________________________________________________________________________________________________|



module adder(
        input_a,
        input_b,
		adder_input_STB,
		adder_BUSY,
        clk,
        rst,
		output_sum,
        adder_output_STB,
        output_module_BUSY
		);

  input     clk;
  input     rst;

  input     [31:0] input_a;

  input     [31:0] input_b;
  
  input     adder_input_STB;
  output    adder_BUSY;
  
  output    [31:0] output_sum;
  
  output    adder_output_STB;
  input     output_module_BUSY;

  //Intermediate registers
  reg       adder_output_STB_reg;
  reg       [31:0] output_sum_reg;
  reg       adder_BUSY_reg;

  reg       [3:0] adder_state;
  
  parameter get_a_and_b   = 4'd0,
            unpack        = 4'd1,
            special_cases = 4'd2,
            align         = 4'd3,
            add_0         = 4'd4,
            add_1         = 4'd5,
            normalise_1   = 4'd6,
            normalise_2   = 4'd7,
            round         = 4'd8,
            pack          = 4'd9,
            put_z         = 4'd10;

  reg       [31:0] a, b, z;
  reg       [26:0] a_m, b_m;
  reg       [23:0] z_m;
  reg       [9:0] a_e, b_e, z_e;
  reg       a_s, b_s, z_s;
  reg       guard, round_bit, sticky;
  reg       [27:0] sum;

  always @(posedge clk)
  begin

    case(adder_state)

      get_a_and_b: //Initial state wait for valid inputs and make BUSY = 0 because it has finished previous operation 
      begin
        adder_BUSY_reg <= 0;
        if (!(adder_BUSY_reg) && adder_input_STB) begin  //Once it gets valid input take that input and start processing.
          a <= input_a;
		  b <= input_b;
          adder_BUSY_reg <= 1; //Turn the BUSY signal on, BUSY = 1 because now it will be busy processing latched inputs and can no more take inputs even if it is valid. 
          adder_state <= unpack;
        end
      end


      unpack:
      begin
        a_m <= {a[22 : 0], 3'd0};
        b_m <= {b[22 : 0], 3'd0};
        a_e <= a[30 : 23] - 127;
        b_e <= b[30 : 23] - 127;
        a_s <= a[31];
        b_s <= b[31];
        adder_state <= special_cases;
      end

      special_cases:
      begin
        //if a is NaN or b is NaN return NaN 
        if ((a_e == 128 && a_m != 0) || (b_e == 128 && b_m != 0)) begin
          z[31] <= 1;
          z[30:23] <= 255;
          z[22] <= 1;
          z[21:0] <= 0;
          adder_state <= put_z;
        //if a is inf return inf
        end else if (a_e == 128) begin
          z[31] <= a_s;
          z[30:23] <= 255;
          z[22:0] <= 0;
          //if a is inf and signs don't match return nan
          if ((b_e == 128) && (a_s != b_s)) begin
              z[31] <= b_s;
              z[30:23] <= 255;
              z[22] <= 1;
              z[21:0] <= 0;
          end
          adder_state <= put_z;
        //if b is inf return inf
        end else if (b_e == 128) begin
          z[31] <= b_s;
          z[30:23] <= 255;
          z[22:0] <= 0;
          adder_state <= put_z;
        //if a is zero return b
        end else if ((($signed(a_e) == -127) && (a_m == 0)) && (($signed(b_e) == -127) && (b_m == 0))) begin
          z[31] <= a_s & b_s;
          z[30:23] <= b_e[7:0] + 127;
          z[22:0] <= b_m[26:3];
          adder_state <= put_z;
        //if a is zero return b
        end else if (($signed(a_e) == -127) && (a_m == 0)) begin
          z[31] <= b_s;
          z[30:23] <= b_e[7:0] + 127;
          z[22:0] <= b_m[26:3];
          adder_state <= put_z;
        //if b is zero return a
        end else if (($signed(b_e) == -127) && (b_m == 0)) begin
          z[31] <= a_s;
          z[30:23] <= a_e[7:0] + 127;
          z[22:0] <= a_m[26:3];
          adder_state <= put_z;
        end else begin
          //Denormalised Number
          if ($signed(a_e) == -127) begin
            a_e <= -126;
          end else begin
            a_m[26] <= 1;
          end
          //Denormalised Number
          if ($signed(b_e) == -127) begin
            b_e <= -126;
          end else begin
            b_m[26] <= 1;
          end
          adder_state <= align;
        end
      end

      align:
      begin
        if ($signed(a_e) > $signed(b_e)) begin
          b_e <= b_e + 1;
          b_m <= b_m >> 1;
          b_m[0] <= b_m[0] | b_m[1];
        end else if ($signed(a_e) < $signed(b_e)) begin
          a_e <= a_e + 1;
          a_m <= a_m >> 1;
          a_m[0] <= a_m[0] | a_m[1];
        end else begin
          adder_state <= add_0;
        end
      end

      add_0:
      begin
        z_e <= a_e;
        if (a_s == b_s) begin
          sum <= a_m + b_m;
          z_s <= a_s;
        end else begin
          if (a_m >= b_m) begin
            sum <= a_m - b_m;
            z_s <= a_s;
          end else begin
            sum <= b_m - a_m;
            z_s <= b_s;
          end
        end
        adder_state <= add_1;
      end

      add_1:
      begin
        if (sum[27]) begin
          z_m <= sum[27:4];
          guard <= sum[3];
          round_bit <= sum[2];
          sticky <= sum[1] | sum[0];
          z_e <= z_e + 1;
        end else begin
          z_m <= sum[26:3];
          guard <= sum[2];
          round_bit <= sum[1];
          sticky <= sum[0];
        end
        adder_state <= normalise_1;
      end

      normalise_1:
      begin
        if (z_m[23] == 0 && $signed(z_e) > -126) begin
          z_e <= z_e - 1;
          z_m <= z_m << 1;
          z_m[0] <= guard;
          guard <= round_bit;
          round_bit <= 0;
        end else begin
          adder_state <= normalise_2;
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
          adder_state <= round;
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
        adder_state <= pack;
      end

      pack:
      begin
        z[22 : 0] <= z_m[22:0];
        z[30 : 23] <= z_e[7:0] + 127;
        z[31] <= z_s;
        if ($signed(z_e) == -126 && z_m[23] == 0) begin
          z[30 : 23] <= 0;
        end
        if ($signed(z_e) == -126 && z_m[23:0] == 24'h0) begin
          z[31] <= 1'b0; // FIX SIGN BUG: -a + a = +0.
        end
        //if overflow occurs, return inf
        if ($signed(z_e) > 127) begin
          z[22 : 0] <= 0;
          z[30 : 23] <= 255;
          z[31] <= z_s;
        end
        adder_state <= put_z;
      end

      put_z: //Final state valid output is ready , make the output STB/VALID = 1, put valid output.
      begin
        adder_output_STB_reg <= 1;
        output_sum_reg <= z;
        if (adder_output_STB_reg && !(output_module_BUSY)) begin //Once output module is no more BUSY it lowers it's busy signal and output is then taken by next module.
          adder_output_STB_reg <= 0; //Output is no more valid.
          adder_state <= get_a_and_b; //Go back to initial state.
        end
      end

    endcase

    if (rst == 1) begin //At Active high reset, module is no more BUSY, go to initial state and wait for valid inputs. Input is don't care and output is don't care , so output VALID/STB = 0.
      adder_state <= get_a_and_b;
      adder_BUSY_reg <= 0; 
      adder_output_STB_reg <= 0;
    end

  end
  
  `ifdef SYNTHESIS_OFF //Purely combinational logic for debugging purpose, based on hexadecimal encoded states it will show named states in waveform 
  //see this register "adder_statename" in ASCII in dump
  reg [8*13:0] adder_statename;//Highest 13 Number of ASCII letters each 8 bits.
  always@* begin
    case (1'b1)
      (adder_state === get_a_and_b)  : adder_statename = "GET_A_AND_B";
      (adder_state === unpack)       : adder_statename = "UNPACK";
      (adder_state === special_cases): adder_statename = "SPECIAL_CASES";//13 ASCII letters
      (adder_state === align)        : adder_statename = "ALIGN";
      (adder_state === add_0)        : adder_statename = "ADD_0";
      (adder_state === add_1)        : adder_statename = "ADD_1";
      (adder_state === normalise_1)  : adder_statename = "NORMALIZE_1";
      (adder_state === normalise_2)  : adder_statename = "NORMALIZE_2";
      (adder_state === round)        : adder_statename = "ROUND";
      (adder_state === pack)         : adder_statename = "PACK";
      (adder_state === put_z)        : adder_statename = "PUT_Z";
    endcase
  end//always
  `endif

  //Continuous assignments
  
  assign adder_BUSY = adder_BUSY_reg;
  assign adder_output_STB = adder_output_STB_reg;
  assign output_sum = output_sum_reg;

endmodule
