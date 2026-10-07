library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity top is
  port (
    clk         : in std_logic;
    reset       : in std_logic;
    step_switch : in std_logic; -- Switch or button to manually step the PC
    display_sel : in std_logic; -- Switch to select what to display ('0' = PC, '1' = ACC)
    seg         : out std_logic_vector(6 downto 0);
    an          : out std_logic_vector(3 downto 0)
  );
end top;

architecture Behavioral of top is

  -- Microprocessor connections
  signal address_bus : std_logic_vector(11 downto 0);
  signal data_bus    : std_logic_vector(15 downto 0);

  -- Debug outputs from microprocessor
  signal debug_pc   : std_logic_vector(11 downto 0);
  signal debug_acc  : std_logic_vector(15 downto 0);
  signal debug_muxB : std_logic_vector(15 downto 0);

  -- Data to display
  signal display_data : std_logic_vector(15 downto 0);

  -- Debouncer signals for manual step
  signal step_sync_0  : std_logic             := '0';
  signal step_sync_1  : std_logic             := '0';
  signal debounce_cnt : unsigned(21 downto 0) := (others => '0');
  signal cpu_clk      : std_logic             := '0';

begin

  -- Debouncer for the step switch to prevent multiple clock edges (bouncing)
  process (clk)
  begin
    if rising_edge(clk) then
      step_sync_0 <= step_switch;
      step_sync_1 <= step_sync_0;

      if step_sync_1 = '1' then
        if debounce_cnt(21) = '0' then
          debounce_cnt <= debounce_cnt + 1;
        else
          cpu_clk <= '1';
        end if;
      else
        debounce_cnt <= (others => '0');
        cpu_clk      <= '0';
      end if;
    end if;
  end process;
  U_CPU : entity work.microprocessor
    port map
    (
      clk         => cpu_clk,
      reset       => reset,
      address_bus => address_bus,
      data_bus    => data_bus,
      debug_pc    => debug_pc,
      debug_acc   => debug_acc,
      debug_muxB  => debug_muxB
    );
  data_bus     <= (others => 'Z');
  display_data <= "0000" & debug_pc when display_sel = '0' else
    debug_acc;

  U_DISPLAY : entity work.seven_segment_driver
    port map
    (
      clk     => clk,
      reset   => reset,
      data_in => display_data,
      seg     => seg,
      an      => an
    );

end Behavioral;
