library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ir_reg is
    Port (
        clk    : in  std_logic;
        reset  : in  std_logic;
        ir_ld  : in  std_logic;
        din    : in  std_logic_vector(15 downto 0);
        opcode : out std_logic_vector(3 downto 0);
        addr   : out std_logic_vector(11 downto 0)
    );
end ir_reg;

architecture Behavioral of ir_reg is
    signal reg : std_logic_vector(15 downto 0);
begin
    process(clk, reset)
    begin
        if reset = '1' then
            reg <= (others => '0');
        elsif rising_edge(clk) then
            if ir_ld = '1' then
                reg <= din;
            end if;
        end if;
    end process;

    opcode <= reg(15 downto 12);
    addr   <= reg(11 downto 0);
end Behavioral;
