set_property PACKAGE_PIN W5 [get_ports CLK]							
set_property IOSTANDARD LVCMOS33 [get_ports CLK]

# CLK
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports CLK]
	
# 4x 7seg Displays
set_property PACKAGE_PIN U2 [get_ports {disp_sel[0]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {disp_sel[0]}]
set_property PACKAGE_PIN U4 [get_ports {disp_sel[1]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {disp_sel[1]}]
set_property PACKAGE_PIN V4 [get_ports {disp_sel[2]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {disp_sel[2]}]
set_property PACKAGE_PIN W4 [get_ports {disp_sel[3]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {disp_sel[3]}]
	
set_property PACKAGE_PIN W7 [get_ports {disp_out[6]}]                    
    set_property IOSTANDARD LVCMOS33 [get_ports {disp_out[6]}]
set_property PACKAGE_PIN W6 [get_ports {disp_out[5]}]                    
    set_property IOSTANDARD LVCMOS33 [get_ports {disp_out[5]}]
set_property PACKAGE_PIN U8 [get_ports {disp_out[4]}]                    
    set_property IOSTANDARD LVCMOS33 [get_ports {disp_out[4]}]
set_property PACKAGE_PIN V8 [get_ports {disp_out[3]}]                    
    set_property IOSTANDARD LVCMOS33 [get_ports {disp_out[3]}]
set_property PACKAGE_PIN U5 [get_ports {disp_out[2]}]                    
    set_property IOSTANDARD LVCMOS33 [get_ports {disp_out[2]}]
set_property PACKAGE_PIN V5 [get_ports {disp_out[1]}]                    
    set_property IOSTANDARD LVCMOS33 [get_ports {disp_out[1]}]
set_property PACKAGE_PIN U7 [get_ports {disp_out[0]}]                    
    set_property IOSTANDARD LVCMOS33 [get_ports {disp_out[0]}]

set_property PACKAGE_PIN R2 [get_ports RST]					
	set_property IOSTANDARD LVCMOS33 [get_ports RST]

# i2c - misc	
set_property PACKAGE_PIN N17 [get_ports {SDA}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {SDA}]
set_property PACKAGE_PIN P18 [get_ports {SCL}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {SCL}]
set_property PACKAGE_PIN P17 [get_ports {IRQ}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {IRQ}]
set_property PACKAGE_PIN R18 [get_ports {SS}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {SS}]

