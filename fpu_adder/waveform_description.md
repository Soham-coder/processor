# sync

Simple Handshake Diagram
![Alt text](./Simple_handsake.PNG?raw=true "Waveform")
======================================================
Data Flow FSM
![Alt text](./FSM.jpg?raw=true "Data Flow FSM")
======================================================
Waveform
![Alt text](./wave.PNG?raw=true "Waveform")
======================================================

Waveform description:
1. At reset(rst), output signal adder_BUSY=0, output signal adder_output_STB=0, and output data lines(output sum) will be in don't care. Note that it gets the value at positive edge of clock so it is a little later.
2. Next input_a and input_b are given and adder_input_STB is made 1. But the data is accepted by the adder only when (adder_input_STB==1) and (adder_BUSY==0) i.e., (STB) && (!BUSY) determines when adder will accept the given valid data (look at (a) and (b)) which is indicated by (transaction) signal in waveform.
3. Next input_a and input_b are given after small delay . But note that adder is still BUSY so it cannot accept data even if it is valid (indicated by adder_input_STB).So if you see the state signal , the adder operates on first input data and stages from (0 to 10-hexadecimal_a) are excercised and BUSY signal is turned off. 
   Only then inputs given are accepted by adder indicated by (transaction) line being high.
4. Next input STB to adder is made low indicating that no more valid inputs. The adder processes on existing inputs and excercises from state (0-10-hexadecimal_a) and BUSY signal is turned off.
5. Output sum validity is indicated by output (adder_output_STB) signal when valid results are given.
6. At first 2 and 3 is given, so result is 5. And at second 4 and 5 is given, so result is 9.
7. Note that all through out the operation, input (output_module_BUSY) signal is low indicating that output module that is connected to adder is ready to accept whenever valid output sum is given. 