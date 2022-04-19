-- -------------------------------------------------------------
-- 
-- File Name: hdl_prj\hdlsrc\Der_Faux_FPGA_V2_optimized\Shift_register.vhd
-- Created: 2022-04-19 09:51:10
-- 
-- Generated by MATLAB 9.8 and HDL Coder 3.16
-- 
-- -------------------------------------------------------------


-- -------------------------------------------------------------
-- 
-- Module: Shift_register
-- Source Path: Der_Faux_FPGA_V2_optimized/Der_Faux_FPGA/Comparator Logic/Shift_register
-- Hierarchy Level: 2
-- 
-- -------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY Shift_register IS
  PORT( clk                               :   IN    std_logic;
        reset                             :   IN    std_logic;
        enb                               :   IN    std_logic;
        enable                            :   IN    std_logic;
        data_in                           :   IN    std_logic;
        data_out                          :   OUT   std_logic
        );
END Shift_register;


ARCHITECTURE rtl OF Shift_register IS

  -- Component Declarations
  COMPONENT SimpleDualPortRAM_singlebit
    GENERIC( AddrWidth                    : integer;
             DataWidth                    : integer
             );
    PORT( clk                             :   IN    std_logic;
          enb                             :   IN    std_logic;
          wr_din                          :   IN    std_logic;
          wr_addr                         :   IN    std_logic_vector(AddrWidth - 1 DOWNTO 0);  -- generic width
          wr_en                           :   IN    std_logic;
          rd_addr                         :   IN    std_logic_vector(AddrWidth - 1 DOWNTO 0);  -- generic width
          rd_dout                         :   OUT   std_logic
          );
  END COMPONENT;

  -- Component Configuration Statements
  FOR ALL : SimpleDualPortRAM_singlebit
    USE ENTITY work.SimpleDualPortRAM_singlebit(rtl);

  -- Signals
  SIGNAL Write_Pointer_Counter1_out1      : unsigned(18 DOWNTO 0);  -- ufix19
  SIGNAL Constant11_out1                  : unsigned(18 DOWNTO 0);  -- ufix19
  SIGNAL Pointer_sum1_sub_cast            : signed(19 DOWNTO 0);  -- sfix20
  SIGNAL Pointer_sum1_sub_cast_1          : signed(19 DOWNTO 0);  -- sfix20
  SIGNAL Pointer_sum1_sub_temp            : signed(19 DOWNTO 0);  -- sfix20
  SIGNAL Pointer_sum1_out1                : unsigned(18 DOWNTO 0);  -- ufix19
  SIGNAL buffer_rsvd                      : std_logic;

BEGIN
  -- Simulink's HDL coder ignores the "UseRAM" setting when the delay block has an external enable port.
  -- During simulation, using a delay block with enable input is preferred to speed up the simulation.
  -- Before VHDL code generation, the delay block needs to be replaced by a RAM block.

  u_dual_port_RAM1 : SimpleDualPortRAM_singlebit
    GENERIC MAP( AddrWidth => 19,
                 DataWidth => 1
                 )
    PORT MAP( clk => clk,
              enb => enb,
              wr_din => data_in,
              wr_addr => std_logic_vector(Write_Pointer_Counter1_out1),
              wr_en => enable,
              rd_addr => std_logic_vector(Pointer_sum1_out1),
              rd_dout => buffer_rsvd
              );

  -- Count limited, Unsigned Counter
  --  initial value   = 0
  --  step value      = 1
  --  count to value  = 524287
  Write_Pointer_Counter1_process : PROCESS (clk, reset)
  BEGIN
    IF reset = '0' THEN
      Write_Pointer_Counter1_out1 <= to_unsigned(16#00000#, 19);
    ELSIF rising_edge(clk) THEN
      IF enb = '1' AND enable = '1' THEN
        Write_Pointer_Counter1_out1 <= Write_Pointer_Counter1_out1 + to_unsigned(16#00001#, 19);
      END IF;
    END IF;
  END PROCESS Write_Pointer_Counter1_process;


  Constant11_out1 <= to_unsigned(16#55F00#, 19);

  Pointer_sum1_sub_cast <= signed(resize(Write_Pointer_Counter1_out1, 20));
  Pointer_sum1_sub_cast_1 <= signed(resize(Constant11_out1, 20));
  Pointer_sum1_sub_temp <= Pointer_sum1_sub_cast - Pointer_sum1_sub_cast_1;
  Pointer_sum1_out1 <= unsigned(Pointer_sum1_sub_temp(18 DOWNTO 0));

  data_out <= buffer_rsvd;

END rtl;

