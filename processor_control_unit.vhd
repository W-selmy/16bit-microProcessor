library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.cpu_pkg.all;

-- Control Unit for a simple processor
-- Target: Spartan 6 (Xilinx)
entity processor_control_unit is
    Port (
        clk      : in  STD_LOGIC;
        reset    : in  STD_LOGIC;
        opcode   : in  STD_LOGIC_VECTOR(3 downto 0);
        acc_z    : in  STD_LOGIC; -- Zero flag from Accumulator
        acc_15   : in  STD_LOGIC; -- Sign bit or MSB from Accumulator
        
        -- Control Signals
        selA     : out STD_LOGIC;
        selB     : out STD_LOGIC;
        alfu_s   : out STD_LOGIC_VECTOR(1 downto 0);
        ir_ld    : out STD_LOGIC;
        pc_ld    : out STD_LOGIC;
        acc_ld   : out STD_LOGIC;
        acc_oe   : out STD_LOGIC; -- Added from diagram
        RnW      : out STD_LOGIC  -- Added from diagram (1=Read, 0=Write)
    );
end processor_control_unit;

architecture Behavioral of processor_control_unit is

    type state_type is (
        ST_FETCH, 
        ST_INC_PC, 
        ST_JMP, 
        ST_STO, 
        ST_READ_OP, 
        ST_ADD, 
        ST_SUB, 
        ST_LDA, 
        ST_WRITE,
        ST_STOP -- Added for STP instruction
    );
    
    signal current_state, next_state : state_type;

begin

    -- State Transition Process
    process(clk, reset)
    begin
        if reset = '1' then
            current_state <= ST_FETCH;
        elsif rising_edge(clk) then
            current_state <= next_state;
        end if;
    end process;

    -- Next State Logic
    process(current_state, opcode, acc_z, acc_15)
    begin
        -- Default: stay in current state (prevent latches)
        next_state <= current_state;
        
        case current_state is
            when ST_FETCH =>
                if opcode = OP_STP then -- STP
                    next_state <= ST_STOP;
                elsif (opcode = OP_JGE and acc_15 = '0') or -- JGE (ACC >= 0)
                      (opcode = OP_JNE and acc_z = '0') or  -- JNE (ACC != 0)
                      (opcode = OP_JMP) then                -- JMP
                    next_state <= ST_JMP;
                else
                    next_state <= ST_INC_PC;
                end if;

            when ST_INC_PC =>
                if opcode = OP_STO then
                    next_state <= ST_STO;
                elsif opcode = OP_ADD or opcode = OP_SUB or opcode = OP_LDA then
                    next_state <= ST_READ_OP;
                else
                    next_state <= ST_FETCH;
                end if;

            when ST_JMP =>
                next_state <= ST_FETCH;

            when ST_STO =>
                next_state <= ST_FETCH;

            when ST_READ_OP =>
                if opcode = OP_ADD then
                    next_state <= ST_ADD;
                elsif opcode = OP_SUB then
                    next_state <= ST_SUB;
                elsif opcode = OP_LDA then
                    next_state <= ST_LDA;
                else
                    next_state <= ST_FETCH;
                end if;

            when ST_ADD | ST_SUB | ST_LDA =>
                next_state <= ST_WRITE;

            when ST_WRITE =>
                next_state <= ST_FETCH;

            when others =>
                next_state <= ST_FETCH;
        end case;
    end process;

    -- Output Logic Process
    process(current_state)
    begin
        -- Default assignments
        selA   <= '0';
        selB   <= '0';
        alfu_s <= "00";
        ir_ld  <= '0';
        pc_ld  <= '0';
        acc_ld <= '0';
        acc_oe <= '0';
        RnW    <= '1'; -- Default to Read

        case current_state is
            when ST_FETCH =>
                selA   <= '0'; -- PC to Address Bus
                RnW    <= '1';
                ir_ld  <= '1';

            when ST_INC_PC =>
                selB   <= '1'; -- Select PC for ALU
                alfu_s <= ALU_INC; -- INC
                pc_ld  <= '1';

            when ST_JMP =>
                selB   <= '1'; -- Select IR for ALU
                alfu_s <= ALU_PASS;
                pc_ld  <= '1';

            when ST_STO =>
                selA   <= '1'; -- IR Address to Bus
                RnW    <= '0'; -- WRITE
                acc_oe <= '1'; -- Accumulator Output Enable

            when ST_READ_OP =>
                selA   <= '1';
                selB   <= '0'; -- Select Data Bus for ALU
                RnW    <= '1';

            when ST_ADD =>
                alfu_s <= ALU_ADD;

            when ST_SUB =>
                alfu_s <= ALU_SUB;

            when ST_LDA =>
                alfu_s <= ALU_PASS;

            when ST_WRITE =>
                acc_ld <= '1';

            when ST_STOP =>
                null; -- Processor halted

            when others =>
                null;
        end case;
    end process;

end Behavioral;
