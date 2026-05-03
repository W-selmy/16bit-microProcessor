library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.cpu_pkg.all;

entity microprocessor is
    Port (
        clk           : in    std_logic;
        reset         : in    std_logic;
        
        -- External Memory Interface
        address_bus   : out   std_logic_vector(11 downto 0);
        data_bus      : inout std_logic_vector(15 downto 0)
    );
end microprocessor;

architecture Structural of microprocessor is

    -- Internal Signals
    signal opcode   : std_logic_vector(3 downto 0);
    signal accZ     : std_logic;
    signal acc15    : std_logic;
    
    signal selA     : std_logic;
    signal selB     : std_logic;
    signal alufs    : std_logic_vector(1 downto 0);
    signal ir_ld    : std_logic;
    signal pc_ld    : std_logic;
    signal acc_ld   : std_logic;
    signal acc_oe   : std_logic;
    signal RnW      : std_logic;

    signal pc_out   : std_logic_vector(11 downto 0);
    signal ir_addr  : std_logic_vector(11 downto 0);
    signal acc_out  : std_logic_vector(15 downto 0);
    signal alu_out  : std_logic_vector(15 downto 0);
    signal muxB_out : std_logic_vector(15 downto 0);

begin

    -- Address Bus MUX (MUXA)
    address_bus <= pc_out when selA = '0' else ir_addr;

    -- Data Bus Driver (for STO)
    data_bus <= acc_out when (RnW = '0' and acc_oe = '1') else (others => 'Z');

    -- ALU Input B MUX (MUXB)
    -- Input 0: Data Bus, Input 1: PC (padded to 16-bit) or IR operand
    process(selB, data_bus, pc_out, ir_addr, opcode)
    begin
        if selB = '0' then
            muxB_out <= data_bus;
        else
            -- If in INC state (selB=1), use PC. If in JMP/others, use IR.
            if opcode = OP_JMP or opcode = OP_JGE or opcode = OP_JNE then
                muxB_out <= "0000" & ir_addr;
            else
                muxB_out <= "0000" & pc_out;
            end if;
        end if;
    end process;

    -- Component Instantiations
    
    U_CTRL: entity work.processor_control_unit
        port map (
            clk => clk, reset => reset, opcode => opcode,
            acc_z => accZ, acc_15 => acc15,
            selA => selA, selB => selB, alfu_s => alufs,
            ir_ld => ir_ld, pc_ld => pc_ld, acc_ld => acc_ld,
            acc_oe => acc_oe, RnW => RnW
        );

    U_ALU: entity work.alu
        port map (
            A => acc_out, B => muxB_out, alufs => alufs, S => alu_out
        );

    U_PC: entity work.pc_reg
        port map (
            clk => clk, reset => reset, pc_ld => pc_ld,
            din => alu_out(11 downto 0), dout => pc_out
        );

    U_ACC: entity work.acc_reg
        port map (
            clk => clk, reset => reset, acc_ld => acc_ld,
            din => alu_out, dout => acc_out,
            accZ => accZ, acc15 => acc15
        );

    U_IR: entity work.ir_reg
        port map (
            clk => clk, reset => reset, ir_ld => ir_ld,
            din => data_bus, opcode => opcode, addr => ir_addr
        );

end Structural;
