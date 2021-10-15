LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY Seven_segment_poti_display IS
    GENERIC(
        ADC_res     : integer   := 5;   -- Resolution of the ADC in Bit
        ADC_res_G4  : integer   := 8    -- Resolution of the ADC for G4 (Delay)
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
END Seven_segment_poti_display ;

ARCHITECTURE rtl OF Seven_segment_poti_display IS
    CONSTANT C_1: std_logic_vector(6 DOWNTO 0) := "1111001";
    CONSTANT C_2: std_logic_vector(6 DOWNTO 0) := "0100100";
    CONSTANT C_3: std_logic_vector(6 DOWNTO 0) := "0110000";
    CONSTANT C_4: std_logic_vector(6 DOWNTO 0) := "0011001";
    CONSTANT C_5: std_logic_vector(6 DOWNTO 0) := "0010010";
    CONSTANT C_6: std_logic_vector(6 DOWNTO 0) := "0000010";
    CONSTANT C_7: std_logic_vector(6 DOWNTO 0) := "1111000";
    CONSTANT C_8: std_logic_vector(6 DOWNTO 0) := "0000000";
    CONSTANT C_9: std_logic_vector(6 DOWNTO 0) := "0001000";
    CONSTANT C_0: std_logic_vector(6 DOWNTO 0) := "1000000";
    CONSTANT C_E: std_logic_vector(6 DOWNTO 0) := "0000110";

    SIGNAL Gvar1_tmp: std_logic_vector(2 DOWNTO 0);
    SIGNAL Gvar2_tmp: std_logic_vector(2 DOWNTO 0);
    SIGNAL Gvar3_tmp: std_logic_vector(2 DOWNTO 0);
    SIGNAL Gvar4_tmp: std_logic_vector(2 DOWNTO 0);
BEGIN

    Gvar1_tmp <= Gvar1(ADC_res-1 DOWNTO ADC_res-3);
    Gvar2_tmp <= Gvar2(ADC_res-1 DOWNTO ADC_res-3);
    Gvar3_tmp <= Gvar3(ADC_res-1 DOWNTO ADC_res-3);
    Gvar4_tmp <= Gvar4(ADC_res_G4-1 DOWNTO ADC_res_G4-3);

    p_reg: PROCESS (rst_n, clk)
    BEGIN
    IF rst_n = '0' THEN
        hex0 <= (OTHERS=>'0');
        hex1 <= (OTHERS=>'0');
        hex2 <= (OTHERS=>'0');
        hex3 <= (OTHERS=>'0');
        hex4 <= (OTHERS=>'0');
        hex5 <= (OTHERS=>'0');
    ELSIF rising_edge(clk) THEN
        CASE Gvar1_tmp is
            WHEN "000" => hex0 <= C_0;
            WHEN "001" => hex0 <= C_1;
            WHEN "010" => hex0 <= C_2;
            WHEN "011" => hex0 <= C_3;
            WHEN "100" => hex0 <= C_4;
            WHEN "101" => hex0 <= C_5;
            WHEN "110" => hex0 <= C_6;
            WHEN "111" => hex0 <= C_7;
            WHEN OTHERS => hex0 <= C_E;
        END CASE;

        CASE Gvar2_tmp is
            WHEN "000" => hex1 <= C_0;
            WHEN "001" => hex1 <= C_1;
            WHEN "010" => hex1 <= C_2;
            WHEN "011" => hex1 <= C_3;
            WHEN "100" => hex1 <= C_4;
            WHEN "101" => hex1 <= C_5;
            WHEN "110" => hex1 <= C_6;
            WHEN "111" => hex1 <= C_7;
            WHEN OTHERS => hex1 <= C_E;
        END CASE;

        CASE Gvar3_tmp is
            WHEN "000" => hex2 <= C_0;
            WHEN "001" => hex2 <= C_1;
            WHEN "010" => hex2 <= C_2;
            WHEN "011" => hex2 <= C_3;
            WHEN "100" => hex2 <= C_4;
            WHEN "101" => hex2 <= C_5;
            WHEN "110" => hex2 <= C_6;
            WHEN "111" => hex2 <= C_7;
            WHEN OTHERS => hex2 <= C_E;
        END CASE;

        CASE Gvar4_tmp is
            WHEN "000" => hex3 <= C_0;
            WHEN "001" => hex3 <= C_1;
            WHEN "010" => hex3 <= C_2;
            WHEN "011" => hex3 <= C_3;
            WHEN "100" => hex3 <= C_4;
            WHEN "101" => hex3 <= C_5;
            WHEN "110" => hex3 <= C_6;
            WHEN "111" => hex3 <= C_7;
            WHEN OTHERS => hex3 <= C_E;
        END CASE;

        hex4 <= C_0;
        hex5 <= C_E;

    END IF;
    END PROCESS;
END ARCHITECTURE rtl;
