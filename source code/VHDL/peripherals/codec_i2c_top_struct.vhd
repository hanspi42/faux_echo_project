-- VHDL Entity ime_lib.codec_i2c_top.symbol
--
-- Created:
--          by - michael.pichler.UNKNOWN (WI18AC33132)
--          at - 15:09:59 09.07.2010
--
-- Generated by Mentor Graphics' HDL Designer(TM) 2008.1b (Build 7)
--
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE ieee.NUMERIC_STD.ALL;

ENTITY codec_i2c_top IS
  PORT (
    --    Host Side
    clk      : IN    std_logic;
    rst_n    : IN    std_logic;
    --    I2C Side
    i2c_sclk : OUT   std_logic;
    i2c_sdat : INOUT std_logic
    );

-- Declarations

END codec_i2c_top;

--
-- VHDL Architecture ime_lib.codec_i2c_top.struct
--
-- Created:
-- by - michael.pichler.UNKNOWN (WI18AC33132)
-- at - 15:09:59 09.07.2010
--
-- Generated by Mentor Graphics' HDL Designer(TM) 2008.1b (Build 7)
--
-- #################################################################################################
--
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

LIBRARY ime_lib;

ARCHITECTURE struct OF codec_i2c_top IS

  -- Architecture declarations

  -- Internal signal declarations
  SIGNAL wr_data : std_logic_vector(23 DOWNTO 0);
  SIGNAL wr_go   : std_logic;
  SIGNAL wr_end  : std_logic;


  -- Component Declarations
  COMPONENT codec_i2c_config
    GENERIC (
      --  Look-up table length
      g_lut_size            :       unsigned(5 DOWNTO 0)  := "110100";  -- = 51 entries
      --  I2C Address Table
      g_audio_i2c_address   :       unsigned(7 DOWNTO 0)  := x"34";
      g_video_i2c_address   :       unsigned(7 DOWNTO 0)  := x"40";
      --  Audio Data Index
      g_reset               :       unsigned(5 DOWNTO 0)  := "00" & x"0";
      g_set_lin_l           :       unsigned(5 DOWNTO 0)  := "00" & x"1";
      g_set_lin_r           :       unsigned(5 DOWNTO 0)  := "00" & x"2";
      g_set_head_l          :       unsigned(5 DOWNTO 0)  := "00" & x"3";
      g_set_head_r          :       unsigned(5 DOWNTO 0)  := "00" & x"4";
      g_a_path_ctrl         :       unsigned(5 DOWNTO 0)  := "00" & x"5";
      g_d_path_ctrl         :       unsigned(5 DOWNTO 0)  := "00" & x"6";
      g_power_on            :       unsigned(5 DOWNTO 0)  := "00" & x"7";
      g_set_format          :       unsigned(5 DOWNTO 0)  := "00" & x"8";
      g_sample_ctrl         :       unsigned(5 DOWNTO 0)  := "00" & x"9";
      g_set_active          :       unsigned(5 DOWNTO 0)  := "00" & x"A";
      --  Video Data Index
      g_set_video           :       unsigned(5 DOWNTO 0)  := "00" & x"B"
      );
    PORT (
      clk                   : IN    std_logic;
      rst_n                 : IN    std_logic;
      wr_end                : IN    std_logic;
      wr_data               : OUT   std_logic_vector (23 DOWNTO 0);
      wr_go                 : OUT   std_logic
      );
  END COMPONENT;
  COMPONENT codec_i2c_ctrl
    GENERIC (
      g_counter_20khz_limit :       unsigned(11 DOWNTO 0) := x"9C4"  -- = 1250
      );
    PORT (
      clk                   : IN    std_logic;
      rst_n                 : IN    std_logic;
      wr_data               : IN    std_logic_vector (23 DOWNTO 0);
      wr_go                 : IN    std_logic;
      i2c_sclk              : OUT   std_logic;
      wr_end                : OUT   std_logic;
      i2c_sdat              : INOUT std_logic
      );
  END COMPONENT;

  -- Optional embedded configurations
  -- pragma synthesis_off
  FOR ALL : codec_i2c_config USE ENTITY ime_lib.codec_i2c_config;
  FOR ALL : codec_i2c_ctrl USE ENTITY ime_lib.codec_i2c_ctrl;
  -- pragma synthesis_on


BEGIN

  -- Instance port mappings.
  i0_ime_i2c_av_config  : codec_i2c_config
    GENERIC MAP (
      --  Look-up table length
      g_lut_size            => "110100",  -- = 51 entries
      --  I2C Address Table
      g_audio_i2c_address   => x"34",
      g_video_i2c_address   => x"40",
      --  Audio Data Index
      g_reset               => "00" & x"0",
      g_set_lin_l           => "00" & x"1",
      g_set_lin_r           => "00" & x"2",
      g_set_head_l          => "00" & x"3",
      g_set_head_r          => "00" & x"4",
      g_a_path_ctrl         => "00" & x"5",
      g_d_path_ctrl         => "00" & x"6",
      g_power_on            => "00" & x"7",
      g_set_format          => "00" & x"8",
      g_sample_ctrl         => "00" & x"9",
      g_set_active          => "00" & x"A",
      --  Video Data Index
      g_set_video           => "00" & x"B"
      )
    PORT MAP (
      --     Host Side
      clk                   => clk,
      rst_n                 => rst_n,
      wr_data               => wr_data,
      wr_go                 => wr_go,
      wr_end                => wr_end
      );
  i0_ime_i2c_controller : codec_i2c_ctrl
    GENERIC MAP (
      g_counter_20khz_limit => x"9C4"     -- = 1250
      )
    PORT MAP (
      --     Host Side
      clk                   => clk,
      rst_n                 => rst_n,
      wr_data               => wr_data,
      wr_go                 => wr_go,
      wr_end                => wr_end,
      --     I2C Side
      i2c_sclk              => i2c_sclk,
      i2c_sdat              => i2c_sdat
      );

END struct;
