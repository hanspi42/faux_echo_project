--------------------------------------------------------------------------------
-- Project : DE2-35 Framework
--------------------------------------------------------------------------------
-- File    : codec_i2c_ctrl.vhd
-- Library : ime_lib
-- Author  : michael.pichler@fhnw.ch
-- Company : Institute of Microelectronics (IME) FHNW
--------------------------------------------------------------------------------
-- Description : Controls the I2C signals
--------------------------------------------------------------------------------
-- $Rev$
-- $Author$
-- $Date::          $
--------------------------------------------------------------------------------

-- Functional Description:
-- =======================
-- I2C is a 2-wire single-master-multiple-slave bus
--
-- Start Condition: A high-to-low transition of the data-signal while the
-- clock is constant high.
-- After 600 ns or more, the clock is also following to low
--
-- Data transfer: Data is ONLY changing while the clock is low. Data must
-- be stable during both edges of the clock-pulse.
-- Minimum clock pulse-width low is 600 ns
-- Minimum clock pulse-width high is 1.3 us
--
-- Stop Condition: Clock must wr_go from low-to-high while Data remains low
-- for at least another 600 ns
--
--
-- This implementation is using an internal 50 kHz clock and chaning I2C-clock
-- and Data only on its rising edge. As a result, all minimum times between two
-- signals are 20 us.
--
-- Note, that the design is using the 50 kHz clock for all FF-operations, and will
-- buffer-up all I/O signals.
--
-- Assumptions:
--  -----------------
--
--   - Host-clock is 50 MHz
--   - I2C clock can operate with a minimal I2C Clock puls width of 20 us for 
--     both high- and low-pulses
--   - wr_go signal from host is registered and glitch-free
--   - I2C data is stable until we give the END signal. Data is NOT copied internally.
--   - END signal is high initially, and will stay high when finished until the next 
--     wr_go-signal is detected
--
--  Special Remarks
--  ---------------
--   - Data transmission is suspended after every 8 data bits for the reception of the 
--     i2c_acknowledge bits, but the i2c_acknowledge bits are NOT registered and processed.

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY codec_i2c_ctrl IS
  GENERIC (
    CONSTANT g_counter_20khz_limit :       unsigned(11 DOWNTO 0) := x"9C4"  -- = 1250
    );
  PORT (
    --  System signals
    clk                            : IN    std_logic;  -- 50 MHz clock
    rst_n                          : IN    std_logic;  -- Reset acvive low
    --  Host control
    wr_data                        : IN    std_logic_vector(23 DOWNTO 0);  -- Slave_addr, sub_addr,data
    wr_go                          : IN    std_logic;  -- wr_go transfor
    wr_end                         : OUT   std_logic;  -- End transfor
    --  I2C pin signals
    i2c_sclk                       : OUT   std_logic;  -- I2C Clock
    i2c_sdat                       : INOUT std_logic  -- I2C Data

    );
END ENTITY codec_i2c_ctrl;

--------------------------------------------------------------------------------

ARCHITECTURE rtl OF codec_i2c_ctrl IS

  TYPE STATE_TYPE IS (idle, init, start, data, stop);

  TYPE t_i2c_registers IS
    RECORD
      operation_end        : std_logic;
      operation_onwr_going : std_logic;
      counter_20khz        : unsigned(11 DOWNTO 0);
      i2c_tx_data          : std_logic_vector(26 DOWNTO 0);
      start_stop_counter   : unsigned(2 DOWNTO 0);
      data_counter         : unsigned(4 DOWNTO 0);
      change_data          : std_logic;
      i2c_sclk             : std_logic;
      i2c_sdat             : std_logic;
    END RECORD t_i2c_registers;

  SIGNAL current_state : STATE_TYPE;
  SIGNAL next_state    : STATE_TYPE;
  SIGNAL r, r_next     : t_i2c_registers;

BEGIN

  p_i2c_controller_comb : PROCESS (current_state, r, wr_go, wr_data)

    VARIABLE v : t_i2c_registers;

  BEGIN

    v                                 := r;  -- Keep variables stable at all times
    next_state                        <= current_state;
    IF wr_go = '1' THEN
      --  Register the "wr_go" signal
      v.operation_onwr_going          := '1';
    END IF;
    IF r.counter_20khz /= g_counter_20khz_limit THEN
      --  Divide down 50 MHz clock to 20 kHz
      v.counter_20khz                 := r.counter_20khz + 1;
    ELSE
      v.counter_20khz                 := (OTHERS => '0');
      CASE current_state IS
        --  Outer state machine:  Blocks
        WHEN idle                                =>
          --  Wait for wr_go signal  
          IF r.operation_onwr_going = '1' THEN
            next_state                <= init;
          END IF;
        WHEN init                                =>
          --  Initialize all parameters
          --  Trick:  Use a 27-bit long register to sequence the data and i2c_ack bits
          next_state                  <= start;
          v.i2c_tx_data(26 DOWNTO 19) := wr_data(23 DOWNTO 16);
          v.i2c_tx_data(18)           := '1';  -- = high-Z for i2c_ack 1
          v.i2c_tx_data(17 DOWNTO 10) := wr_data(15 DOWNTO 8);
          v.i2c_tx_data(9)            := '1';  -- = high-Z for i2c_ack 2
          v.i2c_tx_data(8 DOWNTO 1)   := wr_data(7 DOWNTO 0);
          v.i2c_tx_data(0)            := '1';  -- = high-Z for i2c_ack 3
          v.start_stop_counter        := (OTHERS => '0');
          v.data_counter              := "11100";  -- = 26 (= 27-1), counting down
          v.i2c_sclk                  := '1';
          v.i2c_sdat                  := '1';  -- => keep tri-stated when unused
          v.change_data               := '1';
          v.operation_end             := '0';
        WHEN start                               =>
          IF r.start_stop_counter = "010" THEN
            --  Transmit the I2C start sequence (data wr_goes low before clock wr_goes low)
            v.i2c_sdat                := '0';
          ELSIF r.start_stop_counter = "100" THEN
            v.i2c_sclk                := '0';
          ELSIF r.start_stop_counter = "101" THEN
            next_state                <= data;
          END IF;
          v.start_stop_counter        := r.start_stop_counter + 1;
        WHEN data                                =>
          --  Transmit 27 bits of data. Data is only driven when low, so a logic "1"
          --  at the positions for the i2c_ack bits will leave the bus tri-stated.
          --  First change the data, and keep the clock low, then toggle the clock
          --  Use "change_data" to distinguish between data and clock transitions
          --  Stop transmition after the last bit has been sent
          IF r.data_counter = "00000" THEN
            next_state                <= stop;
            v.i2c_sclk                := '0';
            v.start_stop_counter      := (OTHERS => '0');
          ELSE
            IF r.change_data = '1' THEN  -- update data
                                        --  Clock wr_goes to zero (or stays at zero for the first time)
                                        --  while data is updated
              v.i2c_sdat              := r.i2c_tx_data(26);
              v.i2c_tx_data           := r.i2c_tx_data(25 DOWNTO 0) & '0';
              v.i2c_sclk              := '0';
              v.change_data           := '0';
              v.data_counter          := r.data_counter - 1;
            ELSE
                                        --  Data is kept stable, and clock wr_goes high to sample it.
              v.i2c_sclk              := '1';
              v.change_data           := '1';
            END IF;
          END IF;
        WHEN stop                                =>
          IF r.start_stop_counter = "010" THEN
            --  Transmit the I2C start sequence (data wr_goes low before clock wr_goes low)
            v.i2c_sclk                := '1';
          ELSIF r.start_stop_counter = "101" THEN
            next_state                <= idle;
            v.i2c_sdat                := '1';
            v.operation_onwr_going    := '0';
            v.operation_end           := '1';
          END IF;
          v.start_stop_counter        := r.start_stop_counter + 1;
      END CASE;
    END IF;  --  End 20 kHz divide-down counter condition
    r_next <= v;                        --  Copy variables to signals

  END PROCESS p_i2c_controller_comb;


  --  Synchronous process, update all registers on the rising edge of clock
  p_i2c_controller_reg : PROCESS (rst_n, clk)
  BEGIN

    IF rst_n = '0' THEN
      --  Reset Condition last ... so it gets highest priority at synthesis
      current_state          <= idle;
      r.counter_20khz        <= (OTHERS => '0');
      r.i2c_tx_data          <= (OTHERS => '0');
      r.operation_onwr_going <= '0';
      r.operation_end        <= '1';
      r.i2c_sclk             <= '1';
      r.i2c_sdat             <= '1';
      r.start_stop_counter   <= (OTHERS => '0');
      r.data_counter         <= "11010";
      r.change_data          <= '0';
    ELSIF rising_edge(clk) THEN
      current_state          <= next_state;
      r                      <= r_next;
    END IF;

  END PROCESS p_i2c_controller_reg;

  -- Output assignments
  wr_end   <= r.operation_end;
  i2c_sclk <= r.i2c_sclk;
  -- Only drive the output when the signal is active low, do not drive it actively high
  i2c_sdat <= '0' WHEN r.i2c_sdat = '0' ELSE 'Z';

END ARCHITECTURE rtl;
