#-----------------------------------------------------
# File    : set_location_assignments.tcl
# Author  : michael.pichler@fhnw.ch
# Date    : 04.03.2015
# Company : Institute of Microelectronics (IME) FHNW
# Content : Default Pin Assignment for DE1-SoC Board
#-----------------------------------------------------

#-----------------------------------------------------
# ADC
#-----------------------------------------------------
set_location_assignment PIN_AJ4                         -to adc_cs_n
set_location_assignment PIN_AK4                         -to adc_din
set_location_assignment PIN_AK3                         -to adc_dout
set_location_assignment PIN_AK2                         -to adc_sclk
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to adc_*

#-----------------------------------------------------
# Audio
#-----------------------------------------------------
set_location_assignment PIN_K7                          -to aud_adcdat
set_location_assignment PIN_K8                          -to aud_adclrck
set_location_assignment PIN_H7                          -to aud_bclk
set_location_assignment PIN_J7                          -to aud_dacdat
set_location_assignment PIN_H8                          -to aud_daclrck
set_location_assignment PIN_G7                          -to aud_xck
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to aud_*

set_instance_assignment -name CURRENT_STRENGTH_NEW 4MA  -to aud_dacdat
set_instance_assignment -name CURRENT_STRENGTH_NEW 4MA  -to aud_*k
set_instance_assignment -name SLEW_RATE 1               -to aud_dacdat
set_instance_assignment -name SLEW_RATE 1               -to aud_*k


#-----------------------------------------------------
# CLOCK
#-----------------------------------------------------
set_location_assignment PIN_AF14                        -to clk_50
# set_location_assignment PIN_AA16                        -to clk2_50
# set_location_assignment PIN_Y26                         -to clk3_50
# set_location_assignment PIN_K14                         -to clk4_50
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to clk*

#-----------------------------------------------------
# SDRAM
#-----------------------------------------------------
# set_location_assignment PIN_AK14                        -to dram_addr[0]
# set_location_assignment PIN_AH14                        -to dram_addr[1]
# set_location_assignment PIN_AG15                        -to dram_addr[2]
# set_location_assignment PIN_AE14                        -to dram_addr[3]
# set_location_assignment PIN_AB15                        -to dram_addr[4]
# set_location_assignment PIN_AC14                        -to dram_addr[5]
# set_location_assignment PIN_AD14                        -to dram_addr[6]
# set_location_assignment PIN_AF15                        -to dram_addr[7]
# set_location_assignment PIN_AH15                        -to dram_addr[8]
# set_location_assignment PIN_AG13                        -to dram_addr[9]
# set_location_assignment PIN_AG12                        -to dram_addr[10]
# set_location_assignment PIN_AH13                        -to dram_addr[11]
# set_location_assignment PIN_AJ14                        -to dram_addr[12]
# set_location_assignment PIN_AF13                        -to dram_ba[0]
# set_location_assignment PIN_AJ12                        -to dram_ba[1]
# set_location_assignment PIN_AF11                        -to dram_cas_n
# set_location_assignment PIN_AK13                        -to dram_cke
# set_location_assignment PIN_AG11                        -to dram_cs_n
# set_location_assignment PIN_AH12                        -to dram_clk
# set_location_assignment PIN_AK6                         -to dram_dq[0]
# set_location_assignment PIN_AJ7                         -to dram_dq[1]
# set_location_assignment PIN_AK7                         -to dram_dq[2]
# set_location_assignment PIN_AK8                         -to dram_dq[3]
# set_location_assignment PIN_AK9                         -to dram_dq[4]
# set_location_assignment PIN_AG10                        -to dram_dq[5]
# set_location_assignment PIN_AK11                        -to dram_dq[6]
# set_location_assignment PIN_AJ11                        -to dram_dq[7]
# set_location_assignment PIN_AH10                        -to dram_dq[8]
# set_location_assignment PIN_AJ10                        -to dram_dq[9]
# set_location_assignment PIN_AJ9                         -to dram_dq[10]
# set_location_assignment PIN_AH9                         -to dram_dq[11]
# set_location_assignment PIN_AH8                         -to dram_dq[12]
# set_location_assignment PIN_AH7                         -to dram_dq[13]
# set_location_assignment PIN_AJ6                         -to dram_dq[14]
# set_location_assignment PIN_AJ5                         -to dram_dq[15]
# set_location_assignment PIN_AB13                        -to dram_ldqm
# set_location_assignment PIN_AE13                        -to dram_ras_n
# set_location_assignment PIN_AK12                        -to dram_udqm
# set_location_assignment PIN_AA13                        -to dram_we_n
# set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to dram_*

#-----------------------------------------------------
# I2C for Audio and Video-In
#-----------------------------------------------------
set_location_assignment PIN_J12                         -to fpga_i2c_sclk
set_location_assignment PIN_K12                         -to fpga_i2c_sdat

set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to fpga_i2c_*
set_instance_assignment -name CURRENT_STRENGTH_NEW 4MA  -to fpga_i2c_*
set_instance_assignment -name SLEW_RATE 1               -to fpga_i2c_*

#-----------------------------------------------------
# SEG7
#-----------------------------------------------------
set_location_assignment PIN_AE26                        -to hex0[0]
set_location_assignment PIN_AE27                        -to hex0[1]
set_location_assignment PIN_AE28                        -to hex0[2]
set_location_assignment PIN_AG27                        -to hex0[3]
set_location_assignment PIN_AF28                        -to hex0[4]
set_location_assignment PIN_AG28                        -to hex0[5]
set_location_assignment PIN_AH28                        -to hex0[6]

set_location_assignment PIN_AJ29                        -to hex1[0]
set_location_assignment PIN_AH29                        -to hex1[1]
set_location_assignment PIN_AH30                        -to hex1[2]
set_location_assignment PIN_AG30                        -to hex1[3]
set_location_assignment PIN_AF29                        -to hex1[4]
set_location_assignment PIN_AF30                        -to hex1[5]
set_location_assignment PIN_AD27                        -to hex1[6]

set_location_assignment PIN_AB23                        -to hex2[0]
set_location_assignment PIN_AE29                        -to hex2[1]
set_location_assignment PIN_AD29                        -to hex2[2]
set_location_assignment PIN_AC28                        -to hex2[3]
set_location_assignment PIN_AD30                        -to hex2[4]
set_location_assignment PIN_AC29                        -to hex2[5]
set_location_assignment PIN_AC30                        -to hex2[6]

set_location_assignment PIN_AD26                        -to hex3[0]
set_location_assignment PIN_AC27                        -to hex3[1]
set_location_assignment PIN_AD25                        -to hex3[2]
set_location_assignment PIN_AC25                        -to hex3[3]
set_location_assignment PIN_AB28                        -to hex3[4]
set_location_assignment PIN_AB25                        -to hex3[5]
set_location_assignment PIN_AB22                        -to hex3[6]

set_location_assignment PIN_AA24                        -to hex4[0]
set_location_assignment PIN_Y23                         -to hex4[1]
set_location_assignment PIN_Y24                         -to hex4[2]
set_location_assignment PIN_W22                         -to hex4[3]
set_location_assignment PIN_W24                         -to hex4[4]
set_location_assignment PIN_V23                         -to hex4[5]
set_location_assignment PIN_W25                         -to hex4[6]

set_location_assignment PIN_V25                         -to hex5[0]
set_location_assignment PIN_AA28                        -to hex5[1]
set_location_assignment PIN_Y27                         -to hex5[2]
set_location_assignment PIN_AB27                        -to hex5[3]
set_location_assignment PIN_AB26                        -to hex5[4]
set_location_assignment PIN_AA26                        -to hex5[5]
set_location_assignment PIN_AA25                        -to hex5[6]

set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to hex*[*]
set_instance_assignment -name CURRENT_STRENGTH_NEW 4MA  -to hex*[*]
set_instance_assignment -name SLEW_RATE 1               -to hex*[*]

#-----------------------------------------------------
# IR
#-----------------------------------------------------
# set_location_assignment PIN_AA30                        -to irda_rxd
# set_location_assignment PIN_AB30                        -to irda_txd
# set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to irda_*

#-----------------------------------------------------
# KEY
#-----------------------------------------------------
set_location_assignment PIN_AA14                        -to key[0]
set_location_assignment PIN_AA15                        -to key[1]
set_location_assignment PIN_W15                         -to key[2]
set_location_assignment PIN_Y16                         -to key[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to key[*]

#-----------------------------------------------------
# LED
#-----------------------------------------------------
set_location_assignment PIN_V16                         -to ledr[0]
set_location_assignment PIN_W16                         -to ledr[1]
set_location_assignment PIN_V17                         -to ledr[2]
set_location_assignment PIN_V18                         -to ledr[3]
set_location_assignment PIN_W17                         -to ledr[4]
set_location_assignment PIN_W19                         -to ledr[5]
set_location_assignment PIN_Y19                         -to ledr[6]
set_location_assignment PIN_W20                         -to ledr[7]
set_location_assignment PIN_W21                         -to ledr[8]
set_location_assignment PIN_Y21                         -to ledr[9]

set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to ledr[*]
set_instance_assignment -name CURRENT_STRENGTH_NEW 4MA  -to ledr[*]
set_instance_assignment -name SLEW_RATE 1               -to ledr[*]
#-----------------------------------------------------
# PS2
#-----------------------------------------------------
# set_location_assignment PIN_AD7                         -to ps2_clk
# set_location_assignment PIN_AD9                         -to ps2_clk2
# set_location_assignment PIN_AE7                         -to ps2_dat
# set_location_assignment PIN_AE9                         -to ps2_dat2
# set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to ps2_*

#-----------------------------------------------------
# SW
#-----------------------------------------------------
set_location_assignment PIN_AB12                        -to sw[0]
set_location_assignment PIN_AC12                        -to sw[1]
set_location_assignment PIN_AF9                         -to sw[2]
set_location_assignment PIN_AF10                        -to sw[3]
set_location_assignment PIN_AD11                        -to sw[4]
set_location_assignment PIN_AD12                        -to sw[5]
set_location_assignment PIN_AE11                        -to sw[6]
set_location_assignment PIN_AC9                         -to sw[7]
set_location_assignment PIN_AD10                        -to sw[8]
set_location_assignment PIN_AE12                        -to sw[9]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sw[*]

#-----------------------------------------------------
# Video-In
#-----------------------------------------------------
# set_location_assignment PIN_H15                         -to td_clk27
# set_location_assignment PIN_D2                          -to td_data[0]
# set_location_assignment PIN_B1                          -to td_data[1]
# set_location_assignment PIN_E2                          -to td_data[2]
# set_location_assignment PIN_B2                          -to td_data[3]
# set_location_assignment PIN_D1                          -to td_data[4]
# set_location_assignment PIN_E1                          -to td_data[5]
# set_location_assignment PIN_C2                          -to td_data[6]
# set_location_assignment PIN_B3                          -to td_data[7]
# set_location_assignment PIN_A5                          -to td_hs
# set_location_assignment PIN_F6                          -to td_reset_n
# set_location_assignment PIN_A3                          -to td_vs
# set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to td_*

#-----------------------------------------------------
# VGA
#-----------------------------------------------------
# set_location_assignment PIN_B13                         -to vga_b[0]
# set_location_assignment PIN_G13                         -to vga_b[1]
# set_location_assignment PIN_H13                         -to vga_b[2]
# set_location_assignment PIN_F14                         -to vga_b[3]
# set_location_assignment PIN_H14                         -to vga_b[4]
# set_location_assignment PIN_F15                         -to vga_b[5]
# set_location_assignment PIN_G15                         -to vga_b[6]
# set_location_assignment PIN_J14                         -to vga_b[7]
# set_location_assignment PIN_F10                         -to vga_blank_n
# set_location_assignment PIN_A11                         -to vga_clk
# set_location_assignment PIN_J9                          -to vga_g[0]
# set_location_assignment PIN_J10                         -to vga_g[1]
# set_location_assignment PIN_H12                         -to vga_g[2]
# set_location_assignment PIN_G10                         -to vga_g[3]
# set_location_assignment PIN_G11                         -to vga_g[4]
# set_location_assignment PIN_G12                         -to vga_g[5]
# set_location_assignment PIN_F11                         -to vga_g[6]
# set_location_assignment PIN_E11                         -to vga_g[7]
# set_location_assignment PIN_B11                         -to vga_hs
# set_location_assignment PIN_A13                         -to vga_r[0]
# set_location_assignment PIN_C13                         -to vga_r[1]
# set_location_assignment PIN_E13                         -to vga_r[2]
# set_location_assignment PIN_B12                         -to vga_r[3]
# set_location_assignment PIN_C12                         -to vga_r[4]
# set_location_assignment PIN_D12                         -to vga_r[5]
# set_location_assignment PIN_E12                         -to vga_r[6]
# set_location_assignment PIN_F13                         -to vga_r[7]
# set_location_assignment PIN_C10                         -to vga_sync_n
# set_location_assignment PIN_D11                         -to vga_vs
# set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to vga_*

#-----------------------------------------------------
# GPIO_0, GPIO_0 connect to D5M - 5M Pixel Camera
#-----------------------------------------------------
# set_location_assignment PIN_AC18                        -to d5m_PIXCLK
# set_location_assignment PIN_Y17                         -to d5m_D[11]
# set_location_assignment PIN_Y18                         -to d5m_D[10]
# set_location_assignment PIN_AK16                        -to d5m_D[9]
# set_location_assignment PIN_AK18                        -to d5m_D[8]
# set_location_assignment PIN_AK19                        -to d5m_D[7]
# set_location_assignment PIN_AJ19                        -to d5m_D[6]
# set_location_assignment PIN_AJ17                        -to d5m_D[5]
# set_location_assignment PIN_AJ16                        -to d5m_D[4]
# set_location_assignment PIN_AH18                        -to d5m_D[3]
# set_location_assignment PIN_AH17                        -to d5m_D[2]
# set_location_assignment PIN_AG16                        -to d5m_D[1]
# set_location_assignment PIN_AE16                        -to d5m_D[0]
# set_location_assignment PIN_AA18                        -to d5m_XCLKIN
# set_location_assignment PIN_AA19                        -to d5m_RESET_N
# set_location_assignment PIN_AC20                        -to d5m_TRIGGER
# set_location_assignment PIN_AH19                        -to d5m_STROBE
# set_location_assignment PIN_AJ20                        -to d5m_LVAL
# set_location_assignment PIN_AH20                        -to d5m_FVAL
# set_location_assignment PIN_AK21                        -to d5m_SDATA
# set_location_assignment PIN_AD19                        -to d5m_SCLK
# set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to d5m_*

#-----------------------------------------------------
# GPIO_1, GPIO_1 connect to MTL - Multi-Touch LCD Panel
#-----------------------------------------------------
# set_location_assignment PIN_AA21                        -to mtl_dclk
# set_location_assignment PIN_AC23                        -to mtl_r[0]
# set_location_assignment PIN_AD24                        -to mtl_r[1]
# set_location_assignment PIN_AE23                        -to mtl_r[2]
# set_location_assignment PIN_AE24                        -to mtl_r[3]
# set_location_assignment PIN_AF25                        -to mtl_r[4]
# set_location_assignment PIN_AF26                        -to mtl_r[5]
# set_location_assignment PIN_AG25                        -to mtl_r[6]
# set_location_assignment PIN_AG26                        -to mtl_r[7]
# set_location_assignment PIN_AH24                        -to mtl_g[0]
# set_location_assignment PIN_AH27                        -to mtl_g[1]
# set_location_assignment PIN_AJ27                        -to mtl_g[2]
# set_location_assignment PIN_AK29                        -to mtl_g[3]
# set_location_assignment PIN_AK28                        -to mtl_g[4]
# set_location_assignment PIN_AK26                        -to mtl_g[5]
# set_location_assignment PIN_AH25                        -to mtl_g[6]
# set_location_assignment PIN_AJ25                        -to mtl_b[0]
# set_location_assignment PIN_AJ24                        -to mtl_g[7]
# set_location_assignment PIN_AK24                        -to mtl_b[1]
# set_location_assignment PIN_AG23                        -to mtl_b[2]
# set_location_assignment PIN_AK23                        -to mtl_b[3]
# set_location_assignment PIN_AH23                        -to mtl_b[4]
# set_location_assignment PIN_AK22                        -to mtl_b[5]
# set_location_assignment PIN_AJ22                        -to mtl_b[6]
# set_location_assignment PIN_AH22                        -to mtl_b[7]
# set_location_assignment PIN_AF24                        -to mtl_hsd
# set_location_assignment PIN_AF23                        -to mtl_vsd
# set_location_assignment PIN_AE22                        -to mtl_touch_i2c_scl
# set_location_assignment PIN_AD21                        -to mtl_touch_i2c_sda
# set_location_assignment PIN_AA20                        -to mtl_touch_int_n
# set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to mtl_*

#-----------------------------------------------------
# End of pin assignments
#-----------------------------------------------------
