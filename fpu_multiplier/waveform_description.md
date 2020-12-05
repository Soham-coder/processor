


__Simple Handshake Diagram__

<p align="center">
  <img src="./Simple_handsake.PNG?raw=true" alt="Waveform"/>
</p>


___Block Diagram___

<p align="center">
  <img src="./Block_Diagram.jpg?raw=true" alt="Block_Diagram"/>
</p>



___Specification___


1. A transaction takes place any time the input STB line (mult_input_STB) is true and the output BUSY line (mult_BUSY) is false.
2. Multiplier needs to be careful not to ever lower the output BUSY line (mult_BUSY), unless it is ready to receive data.
3. The input STB (mult_input_STB) line should be raised any time input data is ready for sending. The data source must not wait for multiplier BUSY (mult_BUSY)
to be false before raising the input STB line (mult_input_STB).
4. Busy should be IDLE or 0 (mult_BUSY) when multiplier is not busy.
5. Once input STB (mult_input_STB) is raised, the data being transferred cannot be changed until the clock after the transaction takes place.
6. The Data lines (output_mult) hold the previous valid output any time output STB (mult_output_STB) is false.
7. At Reset output mult_BUSY=0, output mult_output_STB=0, and output data lines will be in don't care.



__Data Flow FSM__

<p align="center">
  <img src="./FSM.jpg?raw=true" alt="Data_Flow_FSM"/>
</p>



__Waveform__

<p align="center">
  <img src="./wave.PNG?raw=true" alt="Waveform"/>
</p>




Waveform description:

1. At reset(rst), output signal mult_BUSY=0, output signal mult_output_STB=0, and output data lines(output mult) will be in don't care. Note that it gets the value at positive edge of clock so it is a little later.

2. Next input_a and input_b are given and mult_input_STB is made 1. But the data is accepted by the multiplier only when (mult_input_STB==1) and (mult_BUSY==0) i.e., (STB) && (!BUSY) determines when adder will accept the given valid data (look at (a) and (b)) which is indicated by (transaction) signal in waveform.

3. Next input_a and input_b are given after small delay . But note that multiplier is still BUSY so it cannot accept data even if it is valid (indicated by mult_input_STB).So if you see the state signal , the adder operates on first input data and stages from (0 to 11-hexadecimal_b) are excercised and BUSY signal is turned off. 
Only then inputs given are accepted by multiplier indicated by (transaction) line being high.

4. Next input STB to multiplier is made low indicating that no more valid inputs. The multiplier processes on existing inputs and excercises from state (0-11-hexadecimal_b) and BUSY signal is turned off.

5. Output product validity is indicated by output (mult_output_STB) signal when valid results are given.

6. At first 2 and 3 is given, so result is 6. And at second 4 and 5 is given, so result is 20.

7. Note that all through out the operation, input (output_module_BUSY) signal is low indicating that output module that is connected to adder is ready to accept whenever valid output mult is given. 