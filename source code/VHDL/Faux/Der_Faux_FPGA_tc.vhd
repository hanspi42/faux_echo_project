-- -------------------------------------------------------------
-- 
-- File Name: E:\Users\Donut\Dokumente\FHNW\7. Semester\pro7E\Matlab\2021a\hdl_coder\Der_Faux_FPGA_ovs150_WL46\Der_Faux_FPGA_tc.vhd
-- Created: 2020-12-24 12:43:09
-- 
-- Generated by MATLAB 9.10 and HDL Coder 3.18
-- 
-- -------------------------------------------------------------


-- -------------------------------------------------------------
-- 
-- Module: Der_Faux_FPGA_tc
-- Source Path: Der_Faux_FPGA_tc
-- Hierarchy Level: 1
-- 
-- Master clock enable input: clk_enable
-- 
-- enb         : identical to clk_enable
-- enb_1_150_0 : 150x slower than clk with last phase
-- enb_1_150_1 : 150x slower than clk with phase 1
-- 
-- -------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY Der_Faux_FPGA_tc IS
  PORT( clk                               :   IN    std_logic;
        reset                             :   IN    std_logic;
        clk_enable                        :   IN    std_logic;
        enb                               :   OUT   std_logic;
        enb_1_150_0                       :   OUT   std_logic;
        enb_1_150_1                       :   OUT   std_logic
        );
END Der_Faux_FPGA_tc;


ARCHITECTURE rtl OF Der_Faux_FPGA_tc IS

  -- Signals
  SIGNAL count150                         : unsigned(7 DOWNTO 0);  -- ufix8
  SIGNAL phase_all                        : std_logic;
  SIGNAL phase_0                          : std_logic;
  SIGNAL phase_0_tmp                      : std_logic;
  SIGNAL phase_1                          : std_logic;
  SIGNAL phase_1_tmp                      : std_logic;

BEGIN
  Counter150 : PROCESS (clk, reset)
  BEGIN
    IF reset = '0' THEN
      count150 <= to_unsigned(1, 8);
    ELSIF rising_edge(clk) THEN
      IF clk_enable = '1' THEN
        IF count150 >= to_unsigned(149, 8) THEN
          count150 <= to_unsigned(0, 8);
        ELSE
          count150 <= count150 + to_unsigned(1, 8);
        END IF;
      END IF;
    END IF; 
  END PROCESS Counter150;

  phase_all <= '1' WHEN clk_enable = '1' ELSE '0';

  temp_process1 : PROCESS (clk, reset)
  BEGIN
    IF reset = '0' THEN
      phase_0 <= '0';
    ELSIF rising_edge(clk) THEN
      IF clk_enable = '1' THEN
        phase_0 <= phase_0_tmp;
      END IF;
    END IF; 
  END PROCESS temp_process1;

  phase_0_tmp <= '1' WHEN count150 = to_unsigned(149, 8) AND clk_enable = '1' ELSE '0';

  temp_process2 : PROCESS (clk, reset)
  BEGIN
    IF reset = '0' THEN
      phase_1 <= '1';
    ELSIF rising_edge(clk) THEN
      IF clk_enable = '1' THEN
        phase_1 <= phase_1_tmp;
      END IF;
    END IF; 
  END PROCESS temp_process2;

  phase_1_tmp <= '1' WHEN count150 = to_unsigned(0, 8) AND clk_enable = '1' ELSE '0';

  enb <=  phase_all AND clk_enable;

  enb_1_150_0 <=  phase_0 AND clk_enable;

  enb_1_150_1 <=  phase_1 AND clk_enable;


END rtl;
