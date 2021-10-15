set_global_assignment -entity "ime_vga_audio_pll" -library "lib_ime_vga_audio_pll" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "ime_vga_audio_pll" -library "lib_ime_vga_audio_pll" -name IP_TOOL_VERSION "18.1"
set_global_assignment -entity "ime_vga_audio_pll" -library "lib_ime_vga_audio_pll" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_ime_vga_audio_pll" -name SPD_FILE [file join $::quartus(sip_path) "ime_vga_audio_pll.spd"]

set_global_assignment -library "lib_ime_vga_audio_pll" -name MISC_FILE [file join $::quartus(sip_path) "ime_vga_audio_pll_sim/ime_vga_audio_pll.vho"]
