--------------------------------------------------------------------------------
-- Project : DE2-35 Framework
--------------------------------------------------------------------------------
-- File    : codec_i2c_config.vhd
-- Library : ime_lib
-- Author  : michael.pichler@fhnw.ch
-- Company : Institute of Microelectronics (IME) FHNW
--------------------------------------------------------------------------------
-- Description : Configuration sequence for the codec
--------------------------------------------------------------------------------
-- $Rev$
-- $Author$
-- $Date::          $
--------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY codec_i2c_config IS
  GENERIC (
    --  Look-up table length
    CONSTANT g_lut_size          : unsigned(5 DOWNTO 0) := "110100";  -- = 51 entries
    --  I2C Address Table
    CONSTANT g_audio_i2c_address : unsigned(7 DOWNTO 0) := x"34";
    CONSTANT g_video_i2c_address : unsigned(7 DOWNTO 0) := x"40";
    --  Audio Data Index
    CONSTANT g_reset             : unsigned(5 DOWNTO 0) := "00" & x"0";
    CONSTANT g_set_lin_l         : unsigned(5 DOWNTO 0) := "00" & x"1";
    CONSTANT g_set_lin_r         : unsigned(5 DOWNTO 0) := "00" & x"2";
    CONSTANT g_set_head_l        : unsigned(5 DOWNTO 0) := "00" & x"3";
    CONSTANT g_set_head_r        : unsigned(5 DOWNTO 0) := "00" & x"4";
    CONSTANT g_a_path_ctrl       : unsigned(5 DOWNTO 0) := "00" & x"5";
    CONSTANT g_d_path_ctrl       : unsigned(5 DOWNTO 0) := "00" & x"6";
    CONSTANT g_power_on          : unsigned(5 DOWNTO 0) := "00" & x"7";
    CONSTANT g_set_format        : unsigned(5 DOWNTO 0) := "00" & x"8";
    CONSTANT g_sample_ctrl       : unsigned(5 DOWNTO 0) := "00" & x"9";
    CONSTANT g_set_active        : unsigned(5 DOWNTO 0) := "00" & x"A";
    --  Video Data Index
    CONSTANT g_set_video         : unsigned(5 DOWNTO 0) := "00" & x"B"
    );

  PORT (
    --  System signals
    clk     : IN  std_logic;
    rst_n   : IN  std_logic;
    --  Host control
    wr_data : OUT std_logic_vector(23 DOWNTO 0);  -- Slave_addr, sub_addr,data
    wr_go   : OUT std_logic;                      -- Go transfor
    wr_end  : IN  std_logic                       -- End transfor
    );

END ENTITY codec_i2c_config;

--------------------------------------------------------------------------------

ARCHITECTURE rtl OF codec_i2c_config IS

  TYPE t_i2c_config_states IS (start, wait_for_end_to_go_away, wait_for_end_to_come_back, finish);
  --
  SIGNAL current_state  : t_i2c_config_states;
  SIGNAL next_state     : t_i2c_config_states;
  --
  SIGNAL wr_go_i        : std_logic;
  SIGNAL wr_go_update   : std_logic;
  --
  SIGNAL wr_data_i      : std_logic_vector(23 DOWNTO 0);
  SIGNAL wr_next_data   : std_logic_vector(23 DOWNTO 0);
  --
  SIGNAL lut_data       : unsigned(15 DOWNTO 0);
  SIGNAL next_lut_data  : unsigned(15 DOWNTO 0);
  --
  SIGNAL lut_index      : unsigned(5 DOWNTO 0);
  SIGNAL lut_next_index : unsigned(5 DOWNTO 0);

BEGIN

  --    Configuration Control
  p_i2c_config_comb : PROCESS (current_state, wr_end, lut_index, lut_data, wr_data_i)

    VARIABLE v_next_state     : t_i2c_config_states;
    VARIABLE v_wr_next_data   : std_logic_vector(23 DOWNTO 0);
    VARIABLE v_lut_next_index : unsigned(5 DOWNTO 0);
    VARIABLE v_next_lut_data  : unsigned(15 DOWNTO 0);
    VARIABLE v_wr_go          : std_logic;

  BEGIN

    v_wr_go          := '0';
    v_lut_next_index := lut_index;
    v_next_state     := start;
    v_wr_next_data   := wr_data_i;

    --  Normal Condition first ...
    IF lut_index = g_lut_size THEN
      --  Only go through the state machine until all table entries are transmitted
      v_next_state         := current_state;
    ELSE
      -- Transmit the next table entry
      CASE current_state IS
        WHEN start                     =>
          --  Kick off the transmission of the next char
          IF lut_index = g_lut_size - 1 THEN
            --  Special case, last in table, to avoid stuck-at warning
            v_wr_next_data := x"8B0000";
          ELSIF lut_index < g_set_video THEN
            --  Configuring Audio Codec
            v_wr_next_data := std_logic_vector(g_audio_i2c_address & lut_data);
          ELSE
            --  Configuring TV-Decoder Chip
            v_wr_next_data := std_logic_vector(g_video_i2c_address & lut_data);
          END IF;
          v_wr_go          := '1';
          v_next_state     := wait_for_end_to_go_away;
        WHEN wait_for_end_to_go_away   =>
          --  Wait for "END" signal to go away as a confirmation that I2C operation has started
          IF wr_end = '0' THEN
            v_next_state   := wait_for_end_to_come_back;
          ELSE
            v_next_state   := wait_for_end_to_go_away;
          END IF;
        WHEN wait_for_end_to_come_back =>
          -- Wait for "END" signal to come back
          IF wr_end = '1' THEN
            v_next_state   := finish;
          ELSE
            v_next_state   := wait_for_end_to_come_back;
          END IF;
        WHEN finish                    =>
          -- Finish: increment Look-up table pointer and go back to start
          v_lut_next_index := lut_index + 1;
          v_next_state     := start;
        WHEN OTHERS                    =>
          v_next_state     := start;
      END CASE;
    END IF;

    CASE v_lut_next_index IS
      --  Audio - Video Configuration look-up table
      --  Refer to the Datasheet of the WM8731 Audio Codec, page 46 and following
      WHEN g_reset          =>
        -- Codec Reset 
        v_next_lut_data := x"1E00";
      WHEN g_set_lin_l      =>
        -- Codec R0:  left input volume = 26 out of 31
        v_next_lut_data := x"0017";
      WHEN g_set_lin_r      =>
        -- Codec R1:  right input volume = 26 out of 31
        v_next_lut_data := x"0217";
      WHEN g_set_head_l     =>
        -- Codec R2:  left headphone: volume = 123 out of 128, zero-cross detect not enabled
        v_next_lut_data := x"047B";
      WHEN g_set_head_r     =>
        -- Codec R3:  right headphone: volume = 123 out of 128, zero-cross detect not enabled
        v_next_lut_data := x"067B";
      WHEN g_a_path_ctrl    =>
        -- Codec R4:  side tone attenuation -15 dB, side tone enabled, 
        -- DAC selected, bypass enabled, line-input to ADC, 
        -- mute disabled, mic boost disabled
        v_next_lut_data := x"0812";
      WHEN g_d_path_ctrl    =>
        -- Codec R5:  clear offset, disable soft-mute, de-emphasis control 48 kHz, enable high-pass filter
        v_next_lut_data := x"0A06";
      WHEN g_power_on       =>
        -- Codec R6:  Disable all power-down features
        v_next_lut_data := x"0C00";
      WHEN g_set_format     =>
        -- Codec R7:  dont invert BCLK, slave-mode, no-swap, MSB on 1st BCLK, 16-bit, MSB right-justified
        v_next_lut_data := x"0E01";
      WHEN g_sample_ctrl    =>
        -- Codec R8:  clockout = core-clock = mclk, 48 kHz sample rate, 256 fs base over-sample
        v_next_lut_data := x"1002";
      WHEN g_set_active     =>
        -- Codec R9:  device is active
        --  Video Configuration
        --  Refer to the Datasheet of the ADV7181B Multiformat SDTV Video Decoder Chip, page 88
        v_next_lut_data := x"1201";
      WHEN g_set_video + 0  =>
        -- Register 0x15:  Slow down digital clamps
        v_next_lut_data := x"1500";
      WHEN g_set_video + 1  =>
        -- Register 0x17:  Set CSFM to SH1
        v_next_lut_data := x"1741";
      WHEN g_set_video + 2  =>
        -- Register 0x3A:  Power-down ADC1 and ADC2
        v_next_lut_data := x"3A16";
      WHEN g_set_video + 3  =>
        -- Register 0x50:  Set DNR threshold
        v_next_lut_data := x"5004";
      WHEN g_set_video + 4  =>
        -- Register 0xC3:  Man mux AIN6 to ADC (0101)
        v_next_lut_data := x"C305";
      WHEN g_set_video + 5  =>
        -- Register 0xC4:  Enable manual muxing
        v_next_lut_data := x"C480";
      WHEN g_set_video + 6  =>
        -- ADI recommended programming sequence
        v_next_lut_data := x"0E80";
      WHEN g_set_video + 7  =>
        -- This sequence must be followed exactly
        v_next_lut_data := x"5020";
      WHEN g_set_video + 8  =>
        -- when setting up the decoder ...
        v_next_lut_data := x"5218";
      WHEN g_set_video + 9  =>
        v_next_lut_data := x"58ED";
      WHEN g_set_video + 10 =>
        v_next_lut_data := x"77C5";
      WHEN g_set_video + 11 =>
        v_next_lut_data := x"7C93";
      WHEN g_set_video + 12 =>
        v_next_lut_data := x"7D00";
      WHEN g_set_video + 13 =>
        v_next_lut_data := x"D048";
      WHEN g_set_video + 14 =>
        v_next_lut_data := x"D5A0";
      WHEN g_set_video + 15 =>
        v_next_lut_data := x"D7EA";
      WHEN g_set_video + 16 =>
        v_next_lut_data := x"E43E";
      WHEN g_set_video + 17 =>
        v_next_lut_data := x"EA0F";
      WHEN g_set_video + 18 =>
        v_next_lut_data := x"3112";
      WHEN g_set_video + 19 =>
        v_next_lut_data := x"3281";
      WHEN g_set_video + 20 =>
        v_next_lut_data := x"3384";
      WHEN g_set_video + 21 =>
        v_next_lut_data := x"37A0";
      WHEN g_set_video + 22 =>
        v_next_lut_data := x"E580";
      WHEN g_set_video + 23 =>
        v_next_lut_data := x"E603";
      WHEN g_set_video + 24 =>
        v_next_lut_data := x"E785";
      WHEN g_set_video + 25 =>
        v_next_lut_data := x"5000";
      WHEN g_set_video + 26 =>
        v_next_lut_data := x"5100";
      WHEN g_set_video + 27 =>
        v_next_lut_data := x"0050";
      WHEN g_set_video + 28 =>
        v_next_lut_data := x"1000";
      WHEN g_set_video + 29 =>
        v_next_lut_data := x"0402";
      WHEN g_set_video + 30 =>
        v_next_lut_data := x"0B00";
      WHEN g_set_video + 31 =>
        v_next_lut_data := x"0A20";
      WHEN g_set_video + 32 =>
        v_next_lut_data := x"1100";
      WHEN g_set_video + 33 =>
        v_next_lut_data := x"2B00";
      WHEN g_set_video + 34 =>
        v_next_lut_data := x"2C8C";
      WHEN g_set_video + 35 =>
        v_next_lut_data := x"2DF2";
      WHEN g_set_video + 36 =>
        v_next_lut_data := x"2EEE";
      WHEN g_set_video + 37 =>
        v_next_lut_data := x"2FF4";
      WHEN g_set_video + 38 =>
        v_next_lut_data := x"30D2";
        --WHEN g_set_video + 39 =>  v_next_lut_data := x"0E05";
      WHEN OTHERS           =>
        v_next_lut_data := x"0E05";
    END CASE;
    --  Copy variable content to real signals
    next_state     <= v_next_state;
    lut_next_index <= v_lut_next_index;
    next_lut_data  <= v_next_lut_data;
    wr_next_data   <= v_wr_next_data;
    wr_go_update   <= v_wr_go;

  END PROCESS p_i2c_config_comb;

  p_i2c_config_reg : PROCESS (rst_n, clk)
  BEGIN

    IF rst_n = '0' THEN
      current_state <= start;
      lut_index     <= (OTHERS  => '0');
      lut_data      <= (OTHERS => '0');
      wr_data_i     <= (OTHERS  => '0');
      wr_go_i       <= '0';
    ELSIF rising_edge(clk) THEN
      current_state <= next_state;
      lut_index     <= lut_next_index;
      lut_data      <= next_lut_data;
      wr_data_i     <= wr_next_data;
      wr_go_i       <= wr_go_update;
    END IF;

  END PROCESS p_i2c_config_reg;

  -- Output assignments
  wr_data <= wr_data_i;
  wr_go   <= wr_go_i;

END ARCHITECTURE rtl;
