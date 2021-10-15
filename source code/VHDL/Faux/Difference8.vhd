-- -------------------------------------------------------------
-- 
-- File Name: E:\Users\Donut\Dokumente\FHNW\7. Semester\pro7E\Matlab\2021a\hdl_coder\Der_Faux_FPGA_ovs150_WL46\Difference8.vhd
-- Created: 2020-12-24 12:43:09
-- 
-- Generated by MATLAB 9.10 and HDL Coder 3.18
-- 
-- -------------------------------------------------------------


-- -------------------------------------------------------------
-- 
-- Module: Difference8
-- Source Path: Der_Faux_FPGA_ovs150_WL46/Der_Faux_FPGA/Difference8
-- Hierarchy Level: 1
-- 
-- -------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY Difference8 IS
  PORT( clk                               :   IN    std_logic;
        reset                             :   IN    std_logic;
        enb                               :   IN    std_logic;
        U                                 :   IN    std_logic_vector(45 DOWNTO 0);  -- sfix46_En41
        Y                                 :   OUT   std_logic_vector(45 DOWNTO 0)  -- sfix46_En52
        );
END Difference8;


ARCHITECTURE rtl OF Difference8 IS

  -- Signals
  SIGNAL U_signed                         : signed(45 DOWNTO 0);  -- sfix46_En41
  SIGNAL U_k_1                            : signed(45 DOWNTO 0);  -- sfix46_En41
  SIGNAL Diff_sub_cast                    : signed(46 DOWNTO 0);  -- sfix47_En41
  SIGNAL Diff_sub_cast_1                  : signed(46 DOWNTO 0);  -- sfix47_En41
  SIGNAL Diff_sub_temp                    : signed(46 DOWNTO 0);  -- sfix47_En41
  SIGNAL Diff_out1                        : signed(45 DOWNTO 0);  -- sfix46_En52

BEGIN
  -- ( U(k) - U(k-1) )
  -- 
  -- U(k)

  U_signed <= signed(U);

  -- 
  -- Store in Global RAM
  UD_process : PROCESS (clk, reset)
  BEGIN
    IF reset = '0' THEN
      U_k_1 <= to_signed(0, 46);
    ELSIF rising_edge(clk) THEN
      IF enb = '1' THEN
        U_k_1 <= U_signed;
      END IF;
    END IF;
  END PROCESS UD_process;


  -- 
  -- Add in CPU
  Diff_sub_cast <= resize(U_signed, 47);
  Diff_sub_cast_1 <= resize(U_k_1, 47);
  Diff_sub_temp <= Diff_sub_cast - Diff_sub_cast_1;
  
  Diff_out1 <= "0111111111111111111111111111111111111111111111" WHEN (Diff_sub_temp(46) = '0') AND (Diff_sub_temp(45 DOWNTO 34) /= "000000000000") ELSE
      "1000000000000000000000000000000000000000000000" WHEN (Diff_sub_temp(46) = '1') AND (Diff_sub_temp(45 DOWNTO 34) /= "111111111111") ELSE
      Diff_sub_temp(34 DOWNTO 0) & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0';

  Y <= std_logic_vector(Diff_out1);

END rtl;

