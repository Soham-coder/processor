


__Simple Handshake Diagram__

<p align="center">
  <img src="./Simple_handsake.PNG?raw=true" alt="Waveform"/>
</p>


___Block Diagram___

<p align="center">
  <img src="./Block_Diagram.jpg?raw=true" alt="Block_Diagram"/>
</p>



___Specification___


1. A transaction takes place any time the input STB line (div_input_STB) is true and the output BUSY line (div_BUSY) is false.
2. Divider needs to be careful not to ever lower the output BUSY line (div_BUSY), unless it is ready to receive data.
3. The input STB (div_input_STB) line should be raised any time input data is ready for sending. The data source must not wait for divider BUSY (div_BUSY) to be false before raising the input STB line (div_input_STB).
4. Busy should be IDLE or 0 (div_BUSY) when divider is not busy.
5. Once input STB (div_input_STB) is raised, the data being transferred cannot be changed until the clock after the transaction takes place.
6. The Data lines (output_div) hold the previous valid output any time output STB (div_output_STB) is false.
7. At Reset output div_BUSY=0, output div_output_STB=0, and output data lines will be in don't care.



__Data Flow FSM__

<p align="center">
  <img src="./FSM.jpg?raw=true" alt="Data_Flow_FSM"/>
</p>



__Waveform__

<p align="center">
  <img src="./wave.PNG?raw=true" alt="Waveform"/>
</p>




Waveform description:

1. At reset(rst), output signal div_BUSY=0, output signal div_output_STB=0, and output data lines(output div) will be in don't care. Note that it gets the value at positive edge of clock so it is a little later.

2. Next input_a and input_b are given and div_input_STB is made 1. But the data is accepted by the divider only when (div_input_STB==1) and (div_BUSY==0) i.e., (STB) && (!BUSY) determines when divider will accept the given valid data (look at (a) and (b)) which is indicated by (transaction) signal in waveform.

3. Next input_a and input_b are given after small delay . But note that divider is still BUSY so it cannot accept data even if it is valid (indicated by div_input_STB).So if you see the state signal , the divider operates on first input data and stages from (0 to 13-hexadecimal_d) are excercised and BUSY signal is turned off. 
Only then inputs given are accepted by divider indicated by (transaction) line being high.

4. Next input STB to divider is made low indicating that no more valid inputs. The divider processes on existing inputs and excercises from state (0-13-hexadecimal_d) and BUSY signal is turned off.

5. Output product validity is indicated by output (div_output_STB) signal when valid results are given.

6. At first 2 and 3 is given, so result is 0.666666686535. And at second 4 and 5 is given, so result is 0.800000011921.

7. Note that all through out the operation, input (output_module_BUSY) signal is low indicating that output module that is connected to divider is ready to accept whenever valid output div is given. 