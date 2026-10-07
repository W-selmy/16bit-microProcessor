library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use work.cpu_pkg.all;

entity tb_microprocessor is
end tb_microprocessor;

architecture Behavioral of tb_microprocessor is

  signal clk         : std_logic := '0';
  signal reset       : std_logic := '0';
  signal address_bus : std_logic_vector(11 downto 0);
  signal data_bus    : std_logic_vector(15 downto 0);

  -- Memory Type
  type mem_array is array (0 to 15) of std_logic_vector(15 downto 0);
  signal memory : mem_array := (
  0      => OP_LDA & x"00A", -- 0: LDA [10]
  1      => OP_ADD & x"00B", -- 1: ADD [11]
  2      => OP_STO & x"00C", -- 2: STO [12]
  3      => OP_STP & x"000", -- 3: STP
  10     => x"0005", -- 10: Data 5
  11     => x"0003", -- 11: Data 3
  others => x"0000"
  );

  constant clk_period : time := 10 ns;

begin
  uut : entity work.microprocessor
    port map
    (
      clk         => clk,
      reset       => reset,
      address_bus => address_bus,
      data_bus    => data_bus
    );

  clk_process : process
  begin
    clk <= '0';
    wait for clk_period/2;
    clk <= '1';
    wait for clk_period/2;
  end process;

  -- Memory Simulation Logic
  process (address_bus, data_bus)
  begin
    -- Simple asynchronous read/write for simulation
    -- In a real system, this would be a separate component
    if to_integer(unsigned(address_bus)) < 16 then
      data_bus <= memory(to_integer(unsigned(address_bus)));
    else
      data_bus <= (others => 'Z');
    end if;
  end process;

  -- Stimulus Process
  stim_proc : process
  begin
    reset <= '1';
    wait for 20 ns;
    reset <= '0';

    -- Let the processor run through the program
    wait for 500 ns;

    assert false report "Simulation Finished" severity note;
    wait;
  end process;

end Behavioral;
