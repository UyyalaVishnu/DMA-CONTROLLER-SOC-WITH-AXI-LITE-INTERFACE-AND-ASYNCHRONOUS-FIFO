# ####################################################################

#  Created by Genus(TM) Synthesis Solution 20.11-s111_1 on Sat Jun 06 12:59:08 IST 2026

# ####################################################################

set sdc_version 2.0

set_units -capacitance 1000fF
set_units -time 1000ps

# Set the current design
current_design dma

create_clock -name "axi_clk" -period 10.0 -waveform {0.0 5.0} [get_ports axi_clk]
create_clock -name "dma_clk" -period 7.0 -waveform {0.0 3.5} [get_ports dma_clk]
set_false_path -from [get_clocks dma_clk] -to [list \
  [get_ports irq]  \
  [get_ports done] ]
set_clock_gating_check -setup 0.0 
set_output_delay -clock [get_clocks axi_clk] -add_delay 2.0 [get_ports s_axi_awready]
set_output_delay -clock [get_clocks axi_clk] -add_delay 2.0 [get_ports s_axi_wready]
set_output_delay -clock [get_clocks axi_clk] -add_delay 2.0 [get_ports {s_axi_bresp[1]}]
set_output_delay -clock [get_clocks axi_clk] -add_delay 2.0 [get_ports {s_axi_bresp[0]}]
set_output_delay -clock [get_clocks axi_clk] -add_delay 2.0 [get_ports s_axi_bvalid]
set_output_delay -clock [get_clocks axi_clk] -add_delay 2.0 [get_ports s_axi_arready]
set_output_delay -clock [get_clocks axi_clk] -add_delay 2.0 [get_ports {s_axi_rdata[31]}]
set_output_delay -clock [get_clocks axi_clk] -add_delay 2.0 [get_ports {s_axi_rdata[30]}]
set_output_delay -clock [get_clocks axi_clk] -add_delay 2.0 [get_ports {s_axi_rdata[29]}]
set_output_delay -clock [get_clocks axi_clk] -add_delay 2.0 [get_ports {s_axi_rdata[28]}]
set_output_delay -clock [get_clocks axi_clk] -add_delay 2.0 [get_ports {s_axi_rdata[27]}]
set_output_delay -clock [get_clocks axi_clk] -add_delay 2.0 [get_ports {s_axi_rdata[26]}]
set_output_delay -clock [get_clocks axi_clk] -add_delay 2.0 [get_ports {s_axi_rdata[25]}]
set_output_delay -clock [get_clocks axi_clk] -add_delay 2.0 [get_ports {s_axi_rdata[24]}]
set_output_delay -clock [get_clocks axi_clk] -add_delay 2.0 [get_ports {s_axi_rdata[23]}]
set_output_delay -clock [get_clocks axi_clk] -add_delay 2.0 [get_ports {s_axi_rdata[22]}]
set_output_delay -clock [get_clocks axi_clk] -add_delay 2.0 [get_ports {s_axi_rdata[21]}]
set_output_delay -clock [get_clocks axi_clk] -add_delay 2.0 [get_ports {s_axi_rdata[20]}]
set_output_delay -clock [get_clocks axi_clk] -add_delay 2.0 [get_ports {s_axi_rdata[19]}]
set_output_delay -clock [get_clocks axi_clk] -add_delay 2.0 [get_ports {s_axi_rdata[18]}]
set_output_delay -clock [get_clocks axi_clk] -add_delay 2.0 [get_ports {s_axi_rdata[17]}]
set_output_delay -clock [get_clocks axi_clk] -add_delay 2.0 [get_ports {s_axi_rdata[16]}]
set_output_delay -clock [get_clocks axi_clk] -add_delay 2.0 [get_ports {s_axi_rdata[15]}]
set_output_delay -clock [get_clocks axi_clk] -add_delay 2.0 [get_ports {s_axi_rdata[14]}]
set_output_delay -clock [get_clocks axi_clk] -add_delay 2.0 [get_ports {s_axi_rdata[13]}]
set_output_delay -clock [get_clocks axi_clk] -add_delay 2.0 [get_ports {s_axi_rdata[12]}]
set_output_delay -clock [get_clocks axi_clk] -add_delay 2.0 [get_ports {s_axi_rdata[11]}]
set_output_delay -clock [get_clocks axi_clk] -add_delay 2.0 [get_ports {s_axi_rdata[10]}]
set_output_delay -clock [get_clocks axi_clk] -add_delay 2.0 [get_ports {s_axi_rdata[9]}]
set_output_delay -clock [get_clocks axi_clk] -add_delay 2.0 [get_ports {s_axi_rdata[8]}]
set_output_delay -clock [get_clocks axi_clk] -add_delay 2.0 [get_ports {s_axi_rdata[7]}]
set_output_delay -clock [get_clocks axi_clk] -add_delay 2.0 [get_ports {s_axi_rdata[6]}]
set_output_delay -clock [get_clocks axi_clk] -add_delay 2.0 [get_ports {s_axi_rdata[5]}]
set_output_delay -clock [get_clocks axi_clk] -add_delay 2.0 [get_ports {s_axi_rdata[4]}]
set_output_delay -clock [get_clocks axi_clk] -add_delay 2.0 [get_ports {s_axi_rdata[3]}]
set_output_delay -clock [get_clocks axi_clk] -add_delay 2.0 [get_ports {s_axi_rdata[2]}]
set_output_delay -clock [get_clocks axi_clk] -add_delay 2.0 [get_ports {s_axi_rdata[1]}]
set_output_delay -clock [get_clocks axi_clk] -add_delay 2.0 [get_ports {s_axi_rdata[0]}]
set_output_delay -clock [get_clocks axi_clk] -add_delay 2.0 [get_ports {s_axi_rresp[1]}]
set_output_delay -clock [get_clocks axi_clk] -add_delay 2.0 [get_ports {s_axi_rresp[0]}]
set_output_delay -clock [get_clocks axi_clk] -add_delay 2.0 [get_ports s_axi_rvalid]
set_output_delay -clock [get_clocks axi_clk] -add_delay 2.0 [get_ports done]
set_output_delay -clock [get_clocks axi_clk] -add_delay 2.0 [get_ports irq]
set_false_path -from [get_ports rst_n]
set_wire_load_mode "enclosed"
