library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- 16-bit Accumulator register with flag generation
-- Implementation: D flip-flop with load enable + combinational flag logic
entity acc_reg is
    Port (
        clk    : in  std_logic;
        reset  : in  std_logic;
        acc_ld : in  std_logic;
        din    : in  std_logic_vector(15 downto 0);
        dout   : out std_logic_vector(15 downto 0);
        accZ   : out std_logic;  -- Zero flag
        acc15  : out std_logic   -- Sign bit (MSB)
    );
end acc_reg;

architecture LogicFunctions of acc_reg is
    signal reg : std_logic_vector(15 downto 0);
begin

    ---------------------------------------------------------------------------
    -- Register (sequential): D flip-flop with async reset and load enable
    ---------------------------------------------------------------------------
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

    ---------------------------------------------------------------------------
    -- Output logic functions (combinational)
    ---------------------------------------------------------------------------
    dout  <= reg;
    acc15 <= reg(15);

    -- Zero flag: NOR of all register bits
    accZ <= not (reg(15) or reg(14) or reg(13) or reg(12) or
                 reg(11) or reg(10) or reg(9)  or reg(8)  or
                 reg(7)  or reg(6)  or reg(5)  or reg(4)  or
                 reg(3)  or reg(2)  or reg(1)  or reg(0));

end LogicFunctions;
