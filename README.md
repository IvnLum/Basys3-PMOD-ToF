# Digilent PMOD ToF I2C VHDL Minimal Controller

Title says it all, based on Digilent' s [[ZyboZ7-20-PmodToF-Demo](https://github.com/Digilent/ZyboZ7-20-PmodToF-Demo)] C implementation for ISL29501
<p align="center">
  <img height=300 src="https://raw.githubusercontent.com/IvnLum/Basys3-PMOD-ToF/main/anim/ToF.gif" alt="animated" />
</p>
<br/>

> In the GIF Basys 3 values are shown in milimiters, this example setup is located pointing from my bed to the roof hence the max distance is 2.8-3.0m!

## You need to manually set register calibration values for your ToF Module!
Since it only implements READ operation, there is no actual calibration . You need to implement it or just obtain Calibration data from a complete controller implementation

<br/>

### The next step is taken only assuming that you calibrate the ToF under exactly the same conditions (lens usage, etc) as in future operations managed from the VHDL controller

<br/>


How can you get those values?, the fastest way is just using  an existing project that implements it on a cheap ESP32 for example, you can borrow this [ToF Controller](https://www.digikey.com/en/maker/projects/add-time-of-flight-sensor-to-arduino-due/1183e70d33804a2e9a88144cd4126c41) C code from Digilent at DigiKey targeted at Arduino Due, ESP32 (the MCU I used) also works but using Arduino libraries (flash it from ArduinoIDE)

<br/>


> **Note:** You need to **modify** the code so it **prints** all written values to calibration register addresses

<br/>


- Register addresses:
```C
unsigned char cali_registers[] = {
                                  0x24, 0x25, 0x26, 0x27,
                                  0x28, 0x29, 0x2A, 0x2B,
                                  0x2C, 0x2D, 0x2E, 0x2F, 0x30
                                  };                                                                                                                                                                                                                                                        
```                                                                                                                                                                                                                                                                                         
                                                                                                                                                                                                                                                                                            
- Register address write:                                                                                                                                                                                                                                                                   
                                                                                                                                                                                                                                                                                            
```C                                                                                                                                                                                                                                                                                        
 write_reg(cali_registers[8], read_reg(0xF6)); //load new register with read value                                                                                                                                                                                                          
```                                                                                                                                                                                                                                                                                         
In the above line **`read_reg(0xF6)`** returns the payload to be written at  **`cali_registers[8]`** direction.                                                                                                                                                                             
                                                                                                                                                                                                                                                                                            
Following that logic is easy to dump its value by simply printing the content of read_reg(0xF6).                                                                                                                                                                                            
                                                                                                                                                                                                                                                                                            
So just by printing all the **`read_reg(0x...)`**  values that imply being written from **`cali_registers[0]`** to **`cali_registers[12]`** we obtain the complete payload for calibration.                                                                                                 
                                                                                                                                                                                                                                                                                            
<br/>                                                                                                                                                                                                                                                                                       
                                                                                                                                                                                                                                                                                            
In my case the ordered values I got:                                                                                                                                                                                                                                                        
                                                                                                                                                                                                                                                                                            
**`0x46 0x52 0xa8 0x47 0x5a 0x73 0xfe 0x00 0x07 0xbd 0x63 0x0f 0xb5`**                                                                                                                                                                                                                      
                                                                                                                                                                                                                                                                                            
After successfully obtaining those values just modify at `i2c_tb.vhd` file the register constant array `constant pmodToF_i2c_registers_values  : reg_addresses :=` replacing the content with your calibration values                                                                       
> **Note:** The ToF controller is located at `" ToF.srcs/sources_1/imports/new/i2c_tb.vhd "`                                                                                                                                                                                                
                                                                                                                                                                                                                                                                                            
Calibration example values in the current file:                                                                                                                                                                                                                                             
```vhdl                                                                                                                                                                                                                                                                                     
   constant pmodToF_i2c_registers_values  : reg_addresses :=                                                                                                                                                                                                                                
       (                                                                                                                                                                                                                                                                                    
            x"46", x"52", x"A8", x"47", x"5A", x"73", x"FE", x"00", x"07", x"BD", x"63", x"0F", x"B5"                                                                                                                                                                                       
       );                                                                                                                                                                                                                                                                                   
```
