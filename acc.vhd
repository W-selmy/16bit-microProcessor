library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity acc_reg is
    Port (
        clk    : in  std_logic;
        reset  : in  std_logic;
        acc_ld : in  std_logic;
        din    : in  std_logic_vector(15 downto 0);
        dout   : out std_logic_vector(15 downto 0);
        accZ   : out std_logic;
        acc15  : out std_logic
    );
end acc_reg;

architecture Behavioral of acc_reg is
    signal reg : std_logic_vector(15 downto 0);
begin
    process(clk, reset)
    begin
        if reset = '1' then
            reg <= (others => '0');
        elsif rising_edge(clk) then
            if acc_ld = '1' then
                reg <= din;
            end if;
        end if;
    end process;

    dout  <= reg;
    acc15 <= reg(15);
    accZ  <= '1' when (unsigned(reg) = 0) else '0';
end Behavioral;
