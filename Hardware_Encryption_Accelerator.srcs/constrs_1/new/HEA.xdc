set_property PACKAGE_PIN K17 [get_ports {sys_clk}]
set_property IOSTANDARD LVCMOS33 [get_ports {sys_clk}]
create_clock -period 8 [get_ports sys_clk]

## uart
set_property PACKAGE_PIN V12 [get_ports {uart}]
set_property IOSTANDARD LVCMOS33 [get_ports {uart}]