


//________IEEE Floating Point Divider (Single Precision)________//


/////////////////////////////________Block Diagram________////////////////////////////////////////////////////////////////////////////////////////////



//                        +------------------------+
//          input_a     =>|                        |=> output_div
//          input_b     =>|                        |
//                        |      divider           |=> div_output_STB
//      div_input_STB   =>|                        |<= output_module_BUSY
//           div_BUSY   <=|                        |
//                        +--------^-|-------------+
//                clk______________| |
//              rst__________________|



/////////////////////////////________Specification________////////////////////////////////////////////////////////////////////////////////////////////

//1. A transaction takes place any time the input STB line (div_input_STB) is true and the output BUSY line (div_BUSY) is false.
//2. Divider needs to be careful not to ever lower the output BUSY line (div_BUSY), unless it is ready to receive data.
//3. The input STB (div_input_STB) line should be raised any time input data is ready for sending. The data source must not wait for divider BUSY (div_BUSY) to be false before raising the input STB line (div_input_STB).
//4. Busy should be IDLE or 0 (div_BUSY) when divider is not busy.
//5. Once input STB (div_input_STB) is raised, the data being transferred cannot be changed until the clock after the transaction takes place.
//6. The Data lines (output_div) hold the previous valid output any time output STB (div_output_STB) is false.
//7. At Reset output div_BUSY=0, output div_output_STB=0, and output data lines will be in don't care.


/////////////////////////////________Port_____List________/////////////////////////////////////////////////////////////////////////////////////////////


//       +__________________________________________________________________________________________________________________________________________________________+
//       |#Port Name           | #Direction  | #Width   |  #Description                                                                                             |
//       |_____________________|_____________|__________|___________________________________________________________________________________________________________|
//       |  input_a            |     input   |     32   |  Input operand a                                                                                          |
//       |  input_b            |     input   |     32   |  Input operand b                                                                                          |
//       |  div_input_STB      |     input   |     1    |  Input valid signal, indicates input is valid                                                             |
//       |  div_BUSY           |     output  |     1    |  Output busy signal, indicates divider is busy and cannot process next input until current one is done    |
//       |  clk                |     input   |     1    |  Clock sample                                                                                             |
//       |  rst                |     input   |     1    |  Active high reset                                                                                        |
//       |  output_div         |     output  |     32   |  Output division result                                                                                   |
//       |  div_output_STB     |     output  |     1    |  Output valid signal, indicates output is valid                                                           |
//       |  output_module_BUSY |     input   |     1    |  Input busy signal, indicates output module is busy, cannot take next input                               |
//       |_____________________|_____________|__________|___________________________________________________________________________________________________________| 


module divider(
        input_a,
        input_b,
        div_input_STB,
	      div_BUSY,
        clk,
        rst,
        output_div,
        div_output_STB,
        output_module_BUSY
        );

  input     clk;
  input     rst;

  input     [31:0] input_a;
  input     [31:0] input_b;

  input     div_input_STB;
  output    div_BUSY;
  

  output    [31:0] output_div;
  output    div_output_STB;
  input     output_module_BUSY;

  //Intermediate registers
  reg       div_output_STB_reg;
  reg       [31:0] output_div_reg;
  reg       div_BUSY_reg;

  reg       [3:0] div_state;
  parameter get_a_and_b   = 4'd0,
            unpack        = 4'd1,
            special_cases = 4'd2,
            normalise_a   = 4'd3,
            normalise_b   = 4'd4,
            divide_0      = 4'd5,
            divide_1      = 4'd6,
            divide_2      = 4'd7,
            divide_3      = 4'd8,
            normalise_1   = 4'd9,
            normalise_2   = 4'd10,
            round         = 4'd11,
            pack          = 4'd12,
            put_z         = 4'd13;

  reg       [31:0] a, b, z;
  reg       [23:0] a_m, b_m, z_m;
  reg       [9:0] a_e, b_e, z_e;
  reg       a_s, b_s, z_s;
  reg       guard, round_bit, sticky;
  reg       [50:0] quotient, divisor, dividend, remainder;
  reg       [5:0] count;

  always @(posedge clk)
  begin

    case(div_state)


      get_a_and_b: //Initial state wait for valid inputs and make BUSY = 0 because it has finished previous operation 
      begin
        div_BUSY_reg <= 0;
        if (!(div_BUSY_reg) && div_input_STB) begin  //Once it gets valid input take that input and start processing.
          a <= input_a;
          b <= input_b;
          div_BUSY_reg <= 1; //Turn the BUSY signal on, BUSY = 1 because now it will be busy processing latched inputs and can no more take inputs even if it is valid. 
          div_state <= unpack;
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
        div_state <= special_cases;
      end

      special_cases:
      begin
        //if a is NaN or b is NaN return NaN 
        if ((a_e == 128 && a_m != 0) || (b_e == 128 && b_m != 0)) begin
          z[31] <= 1;
          z[30:23] <= 255;
          z[22] <= 1;
          z[21:0] <= 0;
          div_state <= put_z;
          //if a is inf and b is inf return NaN 
        end else if ((a_e == 128) && (b_e == 128)) begin
          z[31] <= 1;
          z[30:23] <= 255;
          z[22] <= 1;
          z[21:0] <= 0;
          div_state <= put_z;
        //if a is inf return inf
        end else if (a_e == 128) begin
          z[31] <= a_s ^ b_s;
          z[30:23] <= 255;
          z[22:0] <= 0;
          div_state <= put_z;
           //if b is zero return NaN
          if ($signed(b_e == -127) && (b_m == 0)) begin
            z[31] <= 1;
            z[30:23] <= 255;
            z[22] <= 1;
            z[21:0] <= 0;
            div_state <= put_z;
          end
        //if b is inf return zero
        end else if (b_e == 128) begin
          z[31] <= a_s ^ b_s;
          z[30:23] <= 0;
          z[22:0] <= 0;
          div_state <= put_z;
        //if a is zero return zero
        end else if (($signed(a_e) == -127) && (a_m == 0)) begin
          z[31] <= a_s ^ b_s;
          z[30:23] <= 0;
          z[22:0] <= 0;
          div_state <= put_z;
           //if b is zero return NaN
          if (($signed(b_e) == -127) && (b_m == 0)) begin
            z[31] <= 1;
            z[30:23] <= 255;
            z[22] <= 1;
            z[21:0] <= 0;
            div_state <= put_z;
          end
        //if b is zero return inf
        end else if (($signed(b_e) == -127) && (b_m == 0)) begin
          z[31] <= a_s ^ b_s;
          z[30:23] <= 255;
          z[22:0] <= 0;
          div_state <= put_z;
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
          div_state <= normalise_a;
        end
      end

      normalise_a:
      begin
        if (a_m[23]) begin
          div_state <= normalise_b;
        end else begin
          a_m <= a_m << 1;
          a_e <= a_e - 1;
        end
      end

      normalise_b:
      begin
        if (b_m[23]) begin
          div_state <= divide_0;
        end else begin
          b_m <= b_m << 1;
          b_e <= b_e - 1;
        end
      end

      divide_0:
      begin
        z_s <= a_s ^ b_s;
        z_e <= a_e - b_e;
        quotient <= 0;
        remainder <= 0;
        count <= 0;
        dividend <= a_m << 27;
        divisor <= b_m;
        div_state <= divide_1;
      end

      divide_1:
      begin
        quotient <= quotient << 1;
        remainder <= remainder << 1;
        remainder[0] <= dividend[50];
        dividend <= dividend << 1;
        div_state <= divide_2;
      end

      divide_2:
      begin
        if (remainder >= divisor) begin
          quotient[0] <= 1;
          remainder <= remainder - divisor;
        end
        if (count == 49) begin
          div_state <= divide_3;
        end else begin
          count <= count + 1;
          div_state <= divide_1;
        end
      end

      divide_3:
      begin
        z_m <= quotient[26:3];
        guard <= quotient[2];
        round_bit <= quotient[1];
        sticky <= quotient[0] | (remainder != 0);
        div_state <= normalise_1;
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
          div_state <= normalise_2;
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
          div_state <= round;
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
        div_state <= pack;
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
        div_state <= put_z;
      end
      
      put_z: //Final state valid output is ready , make the output STB/VALID = 1, put valid output.
      begin
        div_output_STB_reg <= 1;
        output_div_reg <= z;
        if (div_output_STB_reg && !(output_module_BUSY)) begin //Once output module is no more BUSY it lowers it's busy signal and output is then taken by next module.
          div_output_STB_reg <= 0; //Output is no more valid.
          div_state <= get_a_and_b; //Go back to initial state.
        end
      end

    endcase
    
    if (rst == 1) begin //At Active high reset, module is no more BUSY, go to initial state and wait for valid inputs. Input is don't care and output is don't care , so output VALID/STB = 0.
      div_state <= get_a_and_b;
      div_BUSY_reg <= 0; 
      div_output_STB_reg <= 0;
    end

  end

   
   `ifdef SYNTHESIS_OFF //Purely combinational logic for debugging purpose, based on hexadecimal encoded states it will show named states in waveform 
   //see this register "div_statename" in ASCII in dump
  reg [8*13:0] div_statename;//Highest 13 Number of ASCII letters each 8 bits.
  always@* begin
    case (1'b1)
      (div_state === get_a_and_b)  : div_statename = "GET_A_AND_B";
      (div_state === unpack)       : div_statename = "UNPACK";
      (div_state === special_cases): div_statename = "SPECIAL_CASES";//13 ASCII letters
      (div_state === normalise_a)  : div_statename = "NORMALISE_A";
      (div_state === normalise_b)  : div_statename = "NORMALISE_B";
      (div_state === divide_0)     : div_statename = "DIVIDE_0";
      (div_state === divide_1)     : div_statename = "DIVIDE_1";
      (div_state === divide_2)     : div_statename = "DIVIDE_2";
      (div_state === divide_3)     : div_statename = "DIVIDE_3";
      (div_state === normalise_1)  : div_statename = "NORMALIZE_1";
      (div_state === normalise_2)  : div_statename = "NORMALIZE_2";
      (div_state === round)        : div_statename = "ROUND";
      (div_state === pack)         : div_statename = "PACK";
      (div_state === put_z)        : div_statename = "PUT_Z";
    endcase
  end//always
  `endif


  //Continuous assignments
  
  assign div_BUSY = div_BUSY_reg;
  assign div_output_STB = div_output_STB_reg;
  assign output_div = output_div_reg;

endmodule

