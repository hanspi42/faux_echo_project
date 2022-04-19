--------------------------------------------------------------------------------
-- Project : DE2-35 Framework
--------------------------------------------------------------------------------
-- File    : ime_reset.vhd
-- Library : ime_lib
-- Author  : michael.pichler@fhnw.ch
-- Company : Institute of Microelectronics (IME) FHNW
--------------------------------------------------------------------------------
-- Description : Global Reset generation
--------------------------------------------------------------------------------
-- $Rev$
-- $Author$
-- $Date::          $
--------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY ime_reset IS
  PORT (
    clk       : IN  std_logic;
    rst_n_ext : IN  std_logic;
    rst_n     : OUT std_logic;
    rst       : OUT std_logic
    );
END ime_reset;

ARCHITECTURE rtl OF ime_reset IS
  SIGNAL sys_rst_n : std_logic;
  SIGNAL sys_rst   : std_logic;
BEGIN
  -- Reset Generation
  p_reset          : PROCESS (rst_n_ext, clk)
  BEGIN

    IF rst_n_ext = '0' THEN
      sys_rst_n <= '0';                 --   Asynchronously activ
      sys_rst   <= '1';                 --   Asynchronously activ
    ELSIF rising_edge(clk) THEN
      sys_rst_n <= '1';                 --   Synchronously passiv
      sys_rst   <= '0';                 --   Synchronously passiv
    END IF;

  END PROCESS p_reset;

  rst_n <= sys_rst_n;
  rst   <= sys_rst;

END rtl;
