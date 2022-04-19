#**************************************************************
# Create Clock
#**************************************************************
create_clock -period 20 -name clk [get_ports {clk_50}]
# TimeQuest has problems with very low clock frequencies. So I define 4.8 MHz instead of 48 KHz
create_clock -name clk_48k -period 208 [get_registers {codec_if:i0_codec_if|clk_48k_i}]

# Automatically constrain PLL and other generated clocks
derive_pll_clocks -create_base_clocks

# between clocks
set_clock_groups -asynchronous -group [get_clocks {clk_48k}] -group [get_clocks {i0_ime_vga_audio_pll|ime_vga_audio_pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}]
set_clock_groups -asynchronous -group [get_clocks {clk}]     -group [get_clocks {i0_ime_vga_audio_pll|ime_vga_audio_pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}]
set_clock_groups -asynchronous -group [get_clocks {clk_48k}] -group [get_clocks {clk}]

# changes 11.09.2020
# set_false_path -from [get_clocks {i0_ime_vga_audio_pll|ime_vga_audio_pll_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk}] -to [get_clocks {i0_ime_vga_audio_pll|ime_vga_audio_pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}]
# set_false_path -from [get_clocks {i0_ime_vga_audio_pll|ime_vga_audio_pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -to [get_clocks {i0_ime_vga_audio_pll|ime_vga_audio_pll_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk}]


#**************************************************************
# Set Input Delay
#**************************************************************
set_input_delay -clock clk 1 [get_ports {fpga_i2c_sdat}]


#**************************************************************
# Set Output Delay
#**************************************************************
set_output_delay -clock clk 1 [all_outputs]


#**************************************************************
# Set False Path
#**************************************************************
# from asynchronous inputs
# set_false_path -from {sw[*]}
set_false_path -from {key[*]}
set_false_path -from {aud_adcdat}
set_false_path -from {adc_*}
# from asynchronous reset
# set_false_path -from {ime_reset:i0_ime_reset|sys_rst}
set_false_path -from {ime_reset:i0_ime_reset|sys_rst_n}

set_false_path -to {aud*}
set_false_path -to {fpga*}
set_false_path -to {adc_*}
# set_false_path -to {ledr[*]}
set_false_path -to {hex*[*]}