LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY The_Faux_Project_top IS
    GENERIC(
        ADC_res     : integer   := 5;   -- Resolution of the ADC in Bit
        ADC_res_G4  : integer   := 8;   -- Resolution of the ADC for G4 (Delay)
        counter_res : integer   := 7
    );
    PORT( 
        clk_50        : IN     std_logic;                      -- Global 50 MHz clock
        key           : IN     std_logic_vector (3 DOWNTO 0);  -- Reset Buttons
        aud_adclrck   : OUT    std_logic;                      -- Audio CODEC ADC LR Clock
        aud_adcdat    : IN     std_logic;                      -- Audio CODEC ADC Data
        aud_bclk      : OUT    std_logic;                      -- Audio CODEC Bit-Stream Clock
        aud_dacdat    : OUT    std_logic;                      -- Audio CODEC DAC Data
        aud_daclrck   : OUT    std_logic;                      -- Audio CODEC DAC LR Clock
        aud_xck       : OUT    std_logic;                      -- Audio CODEC Chip Clock
        fpga_i2c_sclk : OUT    std_logic;                      -- I2C Clock
        fpga_i2c_sdat : INOUT  std_logic;                      -- I2C Data
        hex0          : OUT    std_logic_vector (6 DOWNTO 0);  -- Seven Segment Digit 0
        hex1          : OUT    std_logic_vector (6 DOWNTO 0);  -- Seven Segment Digit 1
        hex2          : OUT    std_logic_vector (6 DOWNTO 0);  -- Seven Segment Digit 2
        hex3          : OUT    std_logic_vector (6 DOWNTO 0);  -- Seven Segment Digit 3
        hex4          : OUT    std_logic_vector (6 DOWNTO 0);  -- Seven Segment Digit 4
        hex5          : OUT    std_logic_vector (6 DOWNTO 0);  -- Seven Segment Digit 5 
        adc_cs_n      : OUT    std_logic;                      -- ADC Chip Select
        adc_din       : OUT    std_logic;                      -- ADC Data In
        adc_dout      : IN     std_logic;                      -- ADC Data Out
        adc_sclk      : OUT    std_logic                       -- ADC Clock
    );

END The_Faux_Project_top ;

ARCHITECTURE struct OF The_Faux_Project_top IS

    SIGNAL clk_18M         : std_logic;    -- 18 MHz Clock for Audio Codec
    SIGNAL clk_7M          : std_logic;    -- 7.2 MHz Clock (48kHz * 150) for Faux model and Peripherals

    SIGNAL locked          : std_logic;
    SIGNAL pin_rst         : std_ulogic;
    SIGNAL rst_n           : std_logic;

    SIGNAL Gvar1_internal  : std_logic_vector(ADC_res-1 DOWNTO 0);
    SIGNAL Gvar2_internal  : std_logic_vector(ADC_res-1  DOWNTO 0);
    SIGNAL Gvar3_internal  : std_logic_vector(ADC_res-1  DOWNTO 0);
    SIGNAL Gvar4_internal  : std_logic_vector(ADC_res_G4-1  DOWNTO 0);

    SIGNAL audio_to_codec  : std_logic_vector(15 DOWNTO 0);
    SIGNAL audio_from_codec: std_logic_vector(15 DOWNTO 0);

    COMPONENT ime_vga_audio_pll
        PORT (
            refclk   : IN     std_logic  := '0';
            rst      : IN     std_logic  := '0';
            locked   : OUT    std_logic;
            outclk_0 : OUT    std_logic;
            outclk_1 : out    std_logic
        );
    END COMPONENT;

    COMPONENT ime_reset
        PORT (
            clk       : IN     std_logic;
            rst_n_ext : IN     std_logic;
            rst       : OUT    std_logic;
            rst_n     : OUT    std_logic
        );
    END COMPONENT;

    COMPONENT ADC_ltc2308_Interface
        GENERIC(
            ADC_res     : integer; -- Resolution of the ADC in Bit
            ADC_res_G4  : integer  -- Resolution of the ADC for G4 (Delay)
        );
        PORT(
          rst_n   :     IN      std_logic; -- Reset, active low
          clk     :     IN      std_logic; -- clock, any frequency up to 40 MHz
          CS_n    :     OUT     std_logic; -- Chip select, avtive low: Rising edge initiates ADC conversion, low enables data transmission on DOUT and DIN
          DIN     :     OUT     std_logic; -- Serial Data from FPGA to ADC
          DOUT    :     IN      std_logic; -- Serial Data from ADC to FPGA
          SCK     :     OUT     std_logic; -- Clock of the serial interface
          Gvar1   :     OUT     std_logic_vector(ADC_res-1 DOWNTO 0); -- Digitized value of poti 1
          Gvar2   :     OUT     std_logic_vector(ADC_res-1 DOWNTO 0); -- Digitized value of poti 2
          Gvar3   :     OUT     std_logic_vector(ADC_res-1 DOWNTO 0); -- Digitized value of poti 3
          Gvar4   :     OUT     std_logic_vector(ADC_res_G4-1 DOWNTO 0); -- Digitized value of poti 4
          data_ready :  OUT     std_logic  -- 1 = All ADC conversions are complete and data at GvarX is valid
        );
    END COMPONENT;

    COMPONENT Seven_segment_poti_display
        GENERIC(
            ADC_res     : integer;   -- Resolution of the ADC in Bit
            ADC_res_G4  : integer    -- Resolution of the ADC for G4 (Delay)
        );
        PORT( 
          clk     : IN     std_logic;
          rst_n   : IN     std_logic;
          hex0    : OUT    std_logic_vector (6 DOWNTO 0);  -- Seven Segment Digit 0
          hex1    : OUT    std_logic_vector (6 DOWNTO 0);  -- Seven Segment Digit 1
          hex2    : OUT    std_logic_vector (6 DOWNTO 0);  -- Seven Segment Digit 2
          hex3    : OUT    std_logic_vector (6 DOWNTO 0);  -- Seven Segment Digit 3
          hex4    : OUT    std_logic_vector (6 DOWNTO 0);  -- Seven Segment Digit 4
          hex5    : OUT    std_logic_vector (6 DOWNTO 0);  -- Seven Segment Digit 5
          Gvar1   : IN     std_logic_vector(ADC_res-1 DOWNTO 0);
          Gvar2   : IN     std_logic_vector(ADC_res-1 DOWNTO 0);
          Gvar3   : IN     std_logic_vector(ADC_res-1 DOWNTO 0);
          Gvar4   : IN     std_logic_vector(ADC_res_G4-1 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT codec_i2c_top
        PORT (
            clk      : IN     std_logic;
            rst_n    : IN     std_logic;
            i2c_sclk : OUT    std_logic;
            i2c_sdat : INOUT  std_logic
        );
    END COMPONENT;

    COMPONENT codec_if
        PORT (
            adc_data                : IN     std_logic;
            clk_18m                 : IN     std_logic;
            left_data_in            : IN     std_logic_vector (15 DOWNTO 0);
            right_data_in           : IN     std_logic_vector (15 DOWNTO 0);
            rst_n                   : IN     std_logic;
            adc_lrclk_48k           : OUT    std_logic;
            bitclk_1536k            : OUT    std_logic;
            clk_1536k               : OUT    std_logic;
            clk_48k                 : OUT    std_logic;
            dac_data                : OUT    std_logic;
            dac_lrclk_48k           : OUT    std_logic;
            left_data_out           : OUT    std_logic_vector (15 DOWNTO 0);
            left_data_out_neg_edge  : OUT    std_logic_vector (15 DOWNTO 0);
            right_data_out          : OUT    std_logic_vector (15 DOWNTO 0);
            right_data_out_neg_edge : OUT    std_logic_vector (15 DOWNTO 0);
            xclk_18m                : OUT    std_logic
        );
    END COMPONENT;


    COMPONENT Der_Faux_FPGA IS
        PORT( 
            clk                               :   IN    std_logic;
            reset                             :   IN    std_logic;
            clk_enable                        :   IN    std_logic;
            Vin                               :   IN    std_logic_vector(15 DOWNTO 0);  -- sfix16_En15
            Gvar1_N                           :   IN    std_logic_vector(4 DOWNTO 0);  -- ufix5
            Gvar2_N                           :   IN    std_logic_vector(4 DOWNTO 0);  -- ufix5
            Gvar3_N                           :   IN    std_logic_vector(4 DOWNTO 0);  -- ufix5
            Gvar4_N                           :   IN    std_logic_vector(7 DOWNTO 0);  -- uint8
            ce_out                            :   OUT   std_logic;
            Vout                              :   OUT   std_logic_vector(15 DOWNTO 0)  -- sfix16_En15
            );
    END COMPONENT;

BEGIN

    pin_rst <= not key(0);

    i0_ime_vga_audio_pll : ime_vga_audio_pll
        PORT MAP (
            refclk   => clk_50,
            rst      => pin_rst,
            outclk_0 => clk_18M,
            outclk_1 => clk_7M,
            locked   => locked
        );
    
    i0_ime_reset : ime_reset
        PORT MAP (
            clk       => clk_50,
            rst_n_ext => locked,
            rst_n     => rst_n,
            rst       => OPEN
        );

    i0_ADC_ltc2308_Interface: ADC_ltc2308_Interface
        GENERIC MAP(
            ADC_res    => ADC_res,
            ADC_res_G4 => ADC_res_G4
        )
        PORT MAP(
            clk     => clk_7M,
            rst_n   => rst_n,
            CS_n    => adc_cs_n,
            DIN     => adc_din,
            DOUT    => adc_dout,
            SCK     => adc_sclk,
            Gvar1   => Gvar1_internal,
            Gvar2   => Gvar2_internal,
            Gvar3   => Gvar3_internal,
            Gvar4   => Gvar4_internal,
            data_ready => open
        );

    i0_Seven_segment_poti_display: Seven_segment_poti_display
        GENERIC MAP(
            ADC_res    => ADC_res,
            ADC_res_G4 => ADC_res_G4
        )
        PORT MAP(
            clk     => clk_7M,
            rst_n => rst_n,
            hex0    => hex0,
            hex1    => hex1,
            hex2    => hex2,
            hex3    => hex3,
            hex4    => hex4,
            hex5    => hex5,
            Gvar1   => Gvar1_internal,
            Gvar2   => Gvar2_internal,
            Gvar3   => Gvar3_internal,
            Gvar4   => Gvar4_internal
        );

    i0_codec_i2c_top : codec_i2c_top
        PORT MAP (
            clk      => clk_50,
            rst_n    => rst_n,
            i2c_sclk => fpga_i2c_sclk,
            i2c_sdat => fpga_i2c_sdat
        );

    i0_codec_if : codec_if
        PORT MAP (
            clk_18m                 => clk_18m,
            rst_n                   => rst_n,
            adc_data                => aud_adcdat,
            dac_data                => aud_dacdat,
            dac_lrclk_48k           => aud_daclrck,
            adc_lrclk_48k           => aud_adclrck,
            bitclk_1536k            => aud_bclk,
            xclk_18m                => aud_xck,
            clk_1536k               => OPEN,
            clk_48k                 => OPEN,
            left_data_in            => audio_to_codec,
            right_data_in           => audio_to_codec,
            left_data_out           => OPEN,
            right_data_out          => OPEN,
            left_data_out_neg_edge  => audio_from_codec,
            right_data_out_neg_edge => OPEN
        ); 
        
    i0_Der_Faux_FPGA: Der_Faux_FPGA
        PORT MAP(
            clk            => clk_7M,
            reset          => rst_n,
            clk_enable     => '1',
            Vin            => audio_from_codec,
            Gvar1_N        => Gvar1_internal,
            Gvar2_N        => Gvar2_internal,
            Gvar3_N        => Gvar3_internal,
            Gvar4_N        => Gvar4_internal,
            ce_out        => OPEN,
            Vout           => audio_to_codec
        );

END struct;
