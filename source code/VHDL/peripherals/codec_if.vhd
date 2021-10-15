--------------------------------------------------------------------------------
-- Project : DE2-35 Framework
--------------------------------------------------------------------------------
-- File    : codec_if.vhd
-- Library : ime_lib
-- Author  : michael.pichler@fhnw.ch
-- Company : Institute of Microelectronics (IME) FHNW
--------------------------------------------------------------------------------
-- Description : Synchronization of the codec signals
--------------------------------------------------------------------------------
-- $Rev$
-- $Author$
-- $Date::          $
--------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY codec_if IS
  PORT (
    --  System signals
    clk_18m                 : IN  std_logic;
    rst_n                   : IN  std_logic;
    --  Audio Side
    adc_data                : IN  std_logic;
    dac_data                : OUT std_logic;
    dac_lrclk_48k           : OUT std_logic;
    adc_lrclk_48k           : OUT std_logic;
    bitclk_1536k            : OUT std_logic;  --  Audio codec bit-Stream clock
    xclk_18m                : OUT std_logic;  --  Audio codec masterclock 18 MHz
    --  Derived clocks
    clk_1536k               : OUT std_logic;
    clk_48k                 : OUT std_logic;
    --  Host Side
    left_data_in            : IN  std_logic_vector(15 DOWNTO 0);
    right_data_in           : IN  std_logic_vector(15 DOWNTO 0);
    left_data_out           : OUT std_logic_vector(15 DOWNTO 0);
    right_data_out          : OUT std_logic_vector(15 DOWNTO 0);
    left_data_out_neg_edge  : OUT std_logic_vector(15 DOWNTO 0);
    right_data_out_neg_edge : OUT std_logic_vector(15 DOWNTO 0)
    );
END ENTITY codec_if;


-- Signal Explanations
--
-- BITCLK Bit-clock for the serial data transfer from and to the Codec, runs at 1536 kHz for
-- 48 kHz sampling rate, 16-bit and 2 channels
-- DACLRC Digital-to-Analog Left-Right Channel selection (high = left ch.), runs at 48 kHz
-- ADCLRC Same as DACLRC but for the Analog-to-Digital direction
-- Both signals must change on the FALLING EDGE of BITCLK !!!
--
-- DACDAT Output serial data, must change on FALLING EDGE of BITCLK !!!
-- ADCDAT Input serial data, must be sampled on RISING EDGE of BITCLK !!!
--
-- Important:
-- In order to have the data ready for outgoing serial transmission, the transmit shift register
-- is loaded BEFORE the 48 kHz pulse, while the received data is updated AFTER the pulse !!!

-- New effort to make the block totally synchronous, based on the 18.432 MHz clock from PLL
-- 1536 kHz Codec Bit-Clock is derived from 18.432 MHz by dividing it with 12
-- 48 kHz is derived from 1536 kHz by dividing it with 32

--------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.std_logic_unsigned.ALL;

ARCHITECTURE rtl OF codec_if IS

  TYPE t_audio_codec_registers IS
    RECORD
      count_1536khz                : natural RANGE 0 TO 5;
      count_48khz                  : natural RANGE 0 TO 15;
      --
      clock_1536k                  : std_logic;
      pulse_48k                    : std_logic;
      pulse_1536k                  : std_logic;
      --
      input_shift_register         : std_logic_vector(31 DOWNTO 0);
      output_shift_register        : std_logic_vector(31 DOWNTO 0);
      --
      codec_left_data_in           : std_logic_vector(15 DOWNTO 0);
      codec_right_data_in          : std_logic_vector(15 DOWNTO 0);
      codec_left_data_in_neg_edge  : std_logic_vector(15 DOWNTO 0);
      codec_right_data_in_neg_edge : std_logic_vector(15 DOWNTO 0);
      --
      serial_codec_output          : std_logic;
    END RECORD t_audio_codec_registers;

  SIGNAL r, r_next    : t_audio_codec_registers;
  SIGNAL clk_48k_i    : std_logic;
  SIGNAL clk_48k_next : std_logic;

BEGIN

  --  Constant routing of clocks and pulses
  adc_lrclk_48k           <= clk_48k_i;
  dac_lrclk_48k           <= clk_48k_i;
  bitclk_1536k            <= r.clock_1536k;
  xclk_18m                <= clk_18m;
  --
  clk_48k                 <= clk_48k_i;
  --
  clk_1536k               <= r.clock_1536k;
  --  Generate serial codec output signal
  dac_data                <= r.serial_codec_output;
  --  Generate parallel data to host
  left_data_out           <= r.codec_left_data_in;
  right_data_out          <= r.codec_right_data_in;
  left_data_out_neg_edge  <= r.codec_left_data_in_neg_edge;
  right_data_out_neg_edge <= r.codec_right_data_in_neg_edge;

  --  Combinatorial logic for the in- and out shift registers
  audio_codec_if_comb_proc : PROCESS (r, clk_48k_i, left_data_in, right_data_in, adc_data)

    VARIABLE v         : t_audio_codec_registers;
    VARIABLE v_clk_48k : std_logic;

  BEGIN

    --  Keep the variables stable with a known value
    v                                             := r;
    v_clk_48k                                     := clk_48k_i;
    --  Reset single-cycle signals
    v.pulse_48k                                   := '0';
    v.pulse_1536k                                 := '0';
    --  Generate 1536 kHz clock 
    --  Divide 18.432 MHz by 12 = flipping 1536kHz signal every 6 cycles of the 18.432 MHz 
    IF r.count_1536khz < 5 THEN
      v.count_1536khz                             := r.count_1536khz + 1;
    ELSE
      v.count_1536khz                             := 0;
      v.clock_1536k                               := NOT r.clock_1536k;
      --  Sample data and generate 1536 kHz pulse on rising edge of 1536 kHz, 
      --  (that is when r.clock_1536k was 0)
      IF r.clock_1536k = '0' THEN
        v.pulse_1536k                             := '1';
        --  Sample serial input on rising edge
        v.input_shift_register                    := r.input_shift_register(30 DOWNTO 0) & adc_data;
      ELSE
        --  Update outgoing serial data on falling edge of BITCLK, 
        v.serial_codec_output                     := r.output_shift_register(30);
        --  Shift  output shift registers
        v.output_shift_register                   := r.output_shift_register(30 DOWNTO 0) & '0';
        --  Generate 48 kHz clock on FALLING EDGE of BITCLK
        --  Divide 1536 kHz by 32 = flipping the 48kHz signal every 16 cycles of 1536 kHz
        IF r.count_48khz < 15 THEN
          v.count_48khz                           := r.count_48khz + 1;
        ELSE
          v.count_48khz                           := 0;
          v_clk_48k                               := NOT clk_48k_i;
                                        -- Reload output shift register on rising edge 
                                        -- (that is when clk_48k is low)
          IF clk_48k_i = '0' THEN
            v.pulse_48k                           := '1';  --  Update output data for serialization
            v.output_shift_register(31 DOWNTO 16) := left_data_in;
            v.output_shift_register(15 DOWNTO 0)  := right_data_in;
            v.serial_codec_output                 := left_data_in(15);  --  Transfer parallelized input data to register
            v.codec_left_data_in                  := r.input_shift_register(31 DOWNTO 16);
            v.codec_right_data_in                 := r.input_shift_register(15 DOWNTO 0);
          ELSE                          -- Alternate edge data to simplify transfer to audio block, if necessary
            v.codec_left_data_in_neg_edge         := r.codec_left_data_in;
            v.codec_right_data_in_neg_edge        := r.codec_right_data_in;
          END IF;  -- Rising edge 48 kHz
        END IF;  -- Generate 48 kHz
      END IF;  -- Rising edge 1536 kHz
    END IF;  -- Generate 1536 kHz
    --  Generate the update signals based on the variable values ...
    r_next       <= v;
    clk_48k_next <= v_clk_48k;

  END PROCESS audio_codec_if_comb_proc;

  --  Register logic for the in- and out shift registers
  audio_io_reg_proc : PROCESS (rst_n, clk_18m)
  BEGIN

    IF rst_n = '0' THEN
      r.count_1536khz                <= 0;
      r.count_48khz                  <= 0;
      --
      clk_48k_i                      <= '0';
      r.clock_1536k                  <= '0';
      r.pulse_48k                    <= '0';
      r.pulse_1536k                  <= '0';
      --
      r.input_shift_register         <= (OTHERS => '0');
      r.output_shift_register        <= (OTHERS => '0');
      --
      r.codec_left_data_in           <= (OTHERS => '0');
      r.codec_right_data_in          <= (OTHERS => '0');
      r.codec_left_data_in_neg_edge  <= (OTHERS => '0');
      r.codec_right_data_in_neg_edge <= (OTHERS => '0');
      --
      r.serial_codec_output          <= '0';
    ELSIF rising_edge(clk_18m) THEN
      r                              <= r_next;
      clk_48k_i                      <= clk_48k_next;
    END IF;

  END PROCESS audio_io_reg_proc;

END ARCHITECTURE rtl;
