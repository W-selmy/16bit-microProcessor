library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity pc_reg is
    Port (
        clk    : in  std_logic;
        reset  : in  std_logic;
        pc_ld  : in  std_logic;
        din    : in  std_logic_vector(11 downto 0);
        dout   : out std_logic_vector(11 downto 0)
    );
end pc_reg;

architecture Behavioral of pc_reg is
begin
    process(clk, reset)
    begin
        if reset = '1' then
            dout <= (others => '0');
        elsif rising_edge(clk) then
            if pc_ld = '1' then
                dout <= din;
            end if;
        end if;
    end process;
end Behavioral;
