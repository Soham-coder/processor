
__Top level state flow diagram__


<p align="center">
  <img src="./top_level_sf_diag.jpg?raw=true" alt="State Flow"/>
</p>




__Final waveform__

![Alt text](./wave.PNG?raw=true "WAVE")




```diff
@@ Wave Description@@
```
At first, in testbench, 
Register[1] of register bank/file is initialised to 2.0
Register[2] is initialised to 3.0

```diff
- Instruction 1 = {2'b00, 5'b00000, 5'b00011, 5'b00001, 5'b00010, 5'b00000, 32'b0}
# Flag(00) - Register operation
# Opcode(00000) - ADD operation
# Rd(00011) - Destination Register address = 3
# Rs1(00001) - Source_1 Register address = 1
# Rs2(00010) - Source_2 Register address = 2
# Program_counter_value(00000) - Current instruction number = 0
# 32_bit immediate value(32'b0) - 32_bit immediate value = 32'b0

Instruction 1 is loaded in PC[0]- 
1st instruction is content(R1) + content(R2) = content(R3) 
--> R type add instruction indicated by flag(00) and opcode(00000)
{i.e., 2.0+3.0 should be stored in R3 after this operation}

- Intruction 2 = {2'b01, 5'b00000, 5'b00011, 5'b00001, 5'b00010, 5'b00000, 32'b0}
# Flag(01) - Immediate operation
# Opcode(00000) - ADD operation
# Rd(00011) - Destination Register address = 3
# Rs1(00001) - Source_1 Register address = 1
# Rs2(00010) - Source_2 Register address = 2
# Program_counter_value(00001) - Current instruction number = 1
# 32_bit immediate value(32'b0) - 32_bit immediate value = 32'b0

Instruction 2 is loaded in PC[1]- 
2nd instruction is content(R1) + 32 bit immediate value = content(R3) 
--> I type add instruction indicated by flag(01) and opcode(00000)
{i.e., 2.0+0.0 should be stored in R3 after this operation}
```

```diff
- FIRST PART
```
At rst , we see from waveform, program counter value is 0, i.e., it is fetching first instruction and executing it i.e., CPU excersises state 0 and 2 and goes to state 1 (indicated by first state[1:0]) and wait for "fetch_stage_enable" poll register to become 1.

We also see that top level controller i.e., instruction decode controller is started (see the signal "start_top_controller").

For the first instruction instruction decode controller excercises states 0, 1 and 2.(indicated by second state[1:0] in waveform). 

In the 1 state it in turn starts the addition_operation sub_controller.

The addition operation subcontroller excercises states 0,1,2,3,4,5,6 (indicated by second state[3:0] in waveform).

In the state 2 it inturn starts the fpu_adder by giving it proper input strobes and data and checking output busy not high.

Fpu_adder excercises states 0,1,2,3,4,5,6,7,8,9,10(hex-a) and after that output is latched by checking output strobe and input busy signal.

We see the inputs to the adder (indicated by a and b) are 2 and 3 respectively for first instruction and output sum (indicated by output_sum) is 5.

Operation type/Flag (indicated by operation_type) is 0 indicating that it is a register operation.

So the value that gets written into register(indicated by WriteData) is 5.0 and the address of the destination register(indicated by WriteReg) is 3 which is correct. 

"RegWrite" is the write enable signal which indicates when write will occur to register file.  

After all stages of the CPU gets completed, we notice that "fetch_stage_enable" register getting high indicating that CPU must fetch the next instruction to get executed.



```diff
- SECOND PART
```
We notice that rst is now low and next instruction is to be executed. CPU enters state 2 and then 1 (indicated by first state[1:0]) and again waits for "fetch_stage_enable" poll register to become 1.

We also see that top level controller i.e., instruction decode controller is started (see the signal "start_top_controller").

For the second instruction instruction decode controller excercises states 0, 1 and 2.(indicated by second state[1:0] in waveform). 
In the 1 state it in turn starts the addition_operation sub_controller.

The addition operation subcontroller excercises states 0,1,2,3,4,5,6 (indicated by second state[3:0] in waveform).

In the state 2 it inturn starts the fpu_adder by giving it proper input strobes and data and checking output busy not high.

Fpu_adder excercises states 0,1,2,10(hex-a) and after that output is latched by checking output strobe and input busy signal.

We see the inputs to the adder (indicated by a and b) are 2 and 0 respectively for second instruction and output sum (indicated by output_sum) is 2.

Operation type/Flag (indicated by operation_type) is 1 indicating that it is a immediate operation.

So the value that gets written into register(indicated by WriteData) is 2.0 and the address of the destination register(indicated by WriteReg) is 3 which is correct. 

"RegWrite" is the write enable signal which indicates when write will occur to register file.  

After all stages of the CPU gets completed, we notice that "fetch_stage_enable" register getting high indicating that CPU must fetch the next instruction to get executed.

And the same process continues ...

Since program counter value is stuck to 1 , same instruction is executed again and again with clock. 


```diff
- EDA Playground link to see hands on- https://www.edaplayground.com/x/Tc64 
```