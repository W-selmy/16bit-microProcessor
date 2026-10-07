library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use work.cpu_pkg.all;

entity alu is
  port (
    A     : in std_logic_vector(15 downto 0);
    B     : in std_logic_vector(15 downto 0);
    alufs : in std_logic_vector(1 downto 0);
    S     : out std_logic_vector(15 downto 0)
  );
end alu;

architecture Behavioral of alu is
begin
  process (A, B, alufs)
  begin
    case alufs is
      when ALU_ADD =>
        S <= std_logic_vector(unsigned(A) + unsigned(B));
      when ALU_SUB =>
        S <= std_logic_vector(unsigned(A) - unsigned(B));
      when ALU_INC =>
        S <= std_logic_vector(unsigned(B) + 1); -- Specifically for PC increment
      when others =>
        S <= B;
    end case;
  end process;
end Behavioral;
