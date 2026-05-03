library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package cpu_pkg is
    -- Opcodes
    constant OP_LDA : std_logic_vector(3 downto 0) := "0000";
    constant OP_STO : std_logic_vector(3 downto 0) := "0001";
    constant OP_ADD : std_logic_vector(3 downto 0) := "0010";
    constant OP_SUB : std_logic_vector(3 downto 0) := "0011";
    constant OP_JMP : std_logic_vector(3 downto 0) := "0100";
    constant OP_JGE : std_logic_vector(3 downto 0) := "0101";
    constant OP_JNE : std_logic_vector(3 downto 0) := "0110";
    constant OP_STP : std_logic_vector(3 downto 0) := "0111";

    -- ALU Operations
    constant ALU_PASS : std_logic_vector(1 downto 0) := "00";
    constant ALU_SUB  : std_logic_vector(1 downto 0) := "01";
    constant ALU_ADD  : std_logic_vector(1 downto 0) := "10";
    constant ALU_INC  : std_logic_vector(1 downto 0) := "11";
end cpu_pkg;
