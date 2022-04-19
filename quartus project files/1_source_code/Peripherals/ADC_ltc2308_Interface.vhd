LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY ADC_ltc2308_Interface IS
    GENERIC(
            -- confreg_SD  : std_logic := '1'; -- 1 = single-ended, 0 = Differential
            -- confreg_OS  : std_logic := '0'; -- 1 = Odd, 0 = Sign
            -- confreg_S1  : std_logic := '0'; -- Multiplexer select bit 1
            -- confreg_S0  : std_logic := '0'; -- Multiplexer select bit 0
            -- confreg_UNI : std_logic := '1'; -- 1 = unipolar, 0 = bipolar
            -- confreg_SLP : std_logic := '0'; -- 1 = sleep mode, 0 = nap mode
            ADC_res     : integer   := 5  ; -- Resolution of the ADC in Bit
            ADC_res_G4  : integer   := 8    -- Resolution of the ADC for G4 (Delay)
        );
    PORT( rst_n   :     IN      std_logic; -- Reset, active low
          clk     :     IN      std_logic; -- clock, any frequency up to 40 MHz
          CS_n    :     OUT     std_logic; -- Chip select, avtive low: Rising edge initiates ADC conversion, low enables data transmission on DOUT and DIN
          DIN     :     OUT     std_logic; -- Serial Data from FPGA to ADC
          DOUT    :     IN      std_logic; -- Serial Data from ADC to FPGA
          SCK     :     OUT     std_logic; -- Clock of the serial interface
          Gvar1   :     OUT     std_logic_vector(ADC_res-1 DOWNTO 0); -- Digitized value of poti 1 in range [0...2^ADC_res-1]
          Gvar2   :     OUT     std_logic_vector(ADC_res-1 DOWNTO 0); -- Digitized value of poti 2 in range [0...2^ADC_res-1]
          Gvar3   :     OUT     std_logic_vector(ADC_res-1 DOWNTO 0); -- Digitized value of poti 3 in range [0...2^ADC_res-1]
          Gvar4   :     OUT     std_logic_vector(ADC_res_G4-1 DOWNTO 0); -- Digitized value of poti 4 in range [0...2^ADC_res_G4-1]
          data_ready :  OUT     std_logic  -- 1 = All ADC conversions are complete and data at GvarX is valid
        );
END ADC_ltc2308_Interface;

ARCHITECTURE rtl OF ADC_ltc2308_Interface IS

    -- State machine types
    TYPE state_type is (state_aquire, state_pass, state_convert);
    TYPE channel_type is (ch1, ch2, ch3, ch4);
    SIGNAL state   : state_type;
    SIGNAL channel : channel_type;

    -- 12 bit Buffers to store the serial data received by the ADC
    SIGNAL rx_buffer1 : std_logic_vector(11 DOWNTO 0);
    SIGNAL rx_buffer2 : std_logic_vector(11 DOWNTO 0);
    SIGNAL rx_buffer3 : std_logic_vector(11 DOWNTO 0);
    SIGNAL rx_buffer4 : std_logic_vector(11 DOWNTO 0);

    -- Configuration bits for each channel. All channels are configured as single-ended, unipolar ADCs without sleep mode.
    CONSTANT ch1_config: std_logic_vector(5 DOWNTO 0) := "100010"; -- select ch0
    CONSTANT ch2_config: std_logic_vector(5 DOWNTO 0) := "110010"; -- select ch1
    CONSTANT ch3_config: std_logic_vector(5 DOWNTO 0) := "110110"; -- select ch3
    CONSTANT ch4_config: std_logic_vector(5 DOWNTO 0) := "111110"; -- select ch7

    -- Control signals
    SIGNAL counter:    integer range 0 to 12 := 0; -- Counts how often the state machine is entered. Resets at every state switch
    SIGNAL index_DIN:  integer range 0 to 6 := 0;  -- Index for serial TX data (FPGA to ADC)
    SIGNAL index_DOUT: integer range 0 to 12 := 0; -- Index for serial RX data (ADC to FPGA)
BEGIN

    switch_state_process: PROCESS(clk, rst_n)
    BEGIN
    IF (state = state_aquire) then
        SCK <= clk;
    ELSE
        SCK <= '0';
    END IF;
    IF (rst_n = '0') THEN
        state <= state_convert;
        channel <= ch1;   

        rx_buffer1 <= (OTHERS=>'0'); -- 000000000000 = Poti has its maximum value
        rx_buffer2 <= (OTHERS=>'0');
        rx_buffer3 <= (OTHERS=>'0');
        rx_buffer4 <= (OTHERS=>'0');

        CS_n <= '1';
        DIN <= '0';
        data_ready <= '0';

        Gvar1 <= (OTHERS=>'0');
        Gvar2 <= (OTHERS=>'0');
        Gvar3 <= (OTHERS=>'0');
        Gvar4 <= (OTHERS=>'0');

        counter <= 0;
        index_DIN <= 0;
        index_DOUT <= 0;
    ELSIF rising_edge(clk) THEN
        counter <= counter +1;
        CASE state IS
            WHEN state_convert =>
                IF (counter = 9) THEN -- 1.3 us to 1.6 us (9 for ovs=128, 4 for ovs=64)
                    state <= state_aquire;
                    counter <= 0;
                    CS_n <= '0';
                ELSE
                    CS_n <= '1';
                END IF;
            WHEN state_aquire =>
                CASE channel IS
                    WHEN ch1 =>
                        IF (counter = 11) THEN
                            rx_buffer1(11-index_DOUT) <= DOUT;
                            index_DOUT <= 0;
                            state <= state_convert; -- state
                            channel <= ch2;  -- switch ch
                            counter <= 0;
                        ELSIF (counter > 5) THEN
                            DIN <= '0';
                            index_DIN <= 0;
                            rx_buffer1(11-index_DOUT) <= DOUT;
                            index_DOUT <= index_DOUT + 1;
                        ELSE
                            DIN <= ch2_config(5-index_DIN);  -- Prepare
                            rx_buffer1(11-index_DOUT) <= DOUT;
                            index_DIN <= index_DIN + 1;
                            index_DOUT <= index_DOUT + 1;
                        END IF;
                    WHEN ch2 =>
                        IF (counter = 11) THEN
                            rx_buffer2(11-index_DOUT) <= DOUT;
                            index_DOUT <= 0;
                            state <= state_convert;
                            channel <= ch3;
                            counter <= 0;
                        ELSIF (counter > 5) THEN
                            DIN <= '0';
                            index_DIN <= 0;
                            rx_buffer2(11-index_DOUT) <= DOUT;
                            index_DOUT <= index_DOUT + 1;
                        ELSE
                            DIN <= ch3_config(5-index_DIN);
                            rx_buffer2(11-index_DOUT) <= DOUT;
                            index_DIN <= index_DIN + 1;
                            index_DOUT <= index_DOUT + 1;
                        END IF;
                    WHEN ch3 =>
                        IF (counter = 11) THEN
                            rx_buffer3(11-index_DOUT) <= DOUT;
                            index_DOUT <= 0;
                            state <= state_convert;
                            channel <= ch4;
                            counter <= 0;
                        ELSIF (counter > 5) THEN
                            DIN <= '0';
                            index_DIN <= 0;
                            rx_buffer3(11-index_DOUT) <= DOUT;
                            index_DOUT <= index_DOUT + 1;
                        ELSE
                            DIN <= ch4_config(5-index_DIN);
                            rx_buffer3(11-index_DOUT) <= DOUT;
                            index_DIN <= index_DIN + 1;
                            index_DOUT <= index_DOUT + 1;
                        END IF;
                    WHEN ch4 =>
                        IF (counter = 11) THEN
                            rx_buffer4(11-index_DOUT) <= DOUT;
                            index_DOUT <= 0;
                            state <= state_pass;
                            data_ready <= '1';
                            channel <= ch1;
                            counter <= 0;
                        ELSIF (counter > 5) THEN
                            DIN <= '0';
                            index_DIN <= 0;
                            rx_buffer4(11-index_DOUT) <= DOUT;
                            index_DOUT <= index_DOUT + 1;
                        ELSE
                            DIN <= ch1_config(5-index_DIN);
                            rx_buffer4(11-index_DOUT) <= DOUT;
                            index_DIN <= index_DIN + 1;
                            index_DOUT <= index_DOUT + 1;
                        END IF;
                    WHEN OTHERS => channel <= ch1;
                END CASE;
            WHEN state_pass =>  Gvar1 <= rx_buffer1(11 DOWNTO 11-ADC_res+1);
                                Gvar2 <= rx_buffer2(11 DOWNTO 11-ADC_res+1);
                                Gvar3 <= rx_buffer3(11 DOWNTO 11-ADC_res+1);
                                Gvar4 <= rx_buffer4(11 DOWNTO 11-ADC_res_G4+1);
                                data_ready <= '0';
                                state <= state_convert;
                                counter <= 0;

            WHEN OTHERS =>  state <= state_convert;
        END CASE;
    END IF;
    END PROCESS switch_state_process;

END ARCHITECTURE rtl;