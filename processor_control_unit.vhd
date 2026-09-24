library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Control Unit for a simple processor
-- Target: Spartan 6 (Xilinx)
-- Implementation: binary-encoded state register with pure
-- combinational logic functions (boolean equations) for
-- state decode, opcode decode, next-state, and outputs.
-- No FSM case statements or when...else constructs.
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
        acc_oe   : out STD_LOGIC; -- Accumulator output enable
        RnW      : out STD_LOGIC  -- 1=Read, 0=Write
    );
end processor_control_unit;

architecture LogicFunctions of processor_control_unit is

    ---------------------------------------------------------------------------
    -- State register: 4 bits, binary-encoded (10 states)
    --
    --   State        Code (s3 s2 s1 s0)
    --   ---------    --------------------
    --   FETCH        0  0  0  0
    --   INC_PC       0  0  0  1
    --   JMP          0  0  1  0
    --   STO          0  0  1  1
    --   READ_OP      0  1  0  0
    --   ADD          0  1  0  1
    --   SUB          0  1  1  0
    --   LDA          0  1  1  1
    --   WRITE        1  0  0  0
    --   STOP         1  0  0  1
    ---------------------------------------------------------------------------
    signal state : std_logic_vector(3 downto 0);

    -- Inverted state bits (used in AND-product state decode)
    signal s3_n, s2_n, s1_n, s0_n : std_logic;

    -- State decode signals (AND-product of state bits)
    signal is_fetch  : std_logic;
    signal is_inc    : std_logic;
    signal is_jmp    : std_logic;
    signal is_sto    : std_logic;
    signal is_read   : std_logic;
    signal is_add    : std_logic;
    signal is_sub    : std_logic;
    signal is_lda    : std_logic;
    signal is_write  : std_logic;
    signal is_stop   : std_logic;

    -- Opcode decode signals (AND-product of opcode bits)
    --   Opcode       Code (o3 o2 o1 o0)
    --   ---------    --------------------
    --   LDA          0  0  0  0
    --   STO          0  0  0  1
    --   ADD          0  0  1  0
    --   SUB          0  0  1  1
    --   JMP          0  1  0  0
    --   JGE          0  1  0  1
    --   JNE          0  1  1  0
    --   STP          0  1  1  1
    signal op_lda     : std_logic;
    signal op_sto     : std_logic;
    signal op_add     : std_logic;
    signal op_sub     : std_logic;
    signal op_stp     : std_logic;
    signal op_mem     : std_logic; -- ADD or SUB or LDA
    signal jmp_taken  : std_logic; -- JMP or (JGE & ACC>=0) or (JNE & ACC/=0)

    -- Next-state bits (one boolean equation each)
    signal next3, next2, next1, next0 : std_logic;

begin

    ---------------------------------------------------------------------------
    -- 1) Inverted state bits
    ---------------------------------------------------------------------------
    s3_n <= not state(3);
    s2_n <= not state(2);
    s1_n <= not state(1);
    s0_n <= not state(0);

    ---------------------------------------------------------------------------
    -- 2) State decode: AND-gate products of state bits
    --    Each signal is '1' only in the corresponding state.
    ---------------------------------------------------------------------------
    is_fetch <= s3_n and s2_n and s1_n and s0_n;             -- 0000
    is_inc   <= s3_n and s2_n and s1_n and state(0);         -- 0001
    is_jmp   <= s3_n and s2_n and state(1) and s0_n;         -- 0010
    is_sto   <= s3_n and s2_n and state(1) and state(0);     -- 0011
    is_read  <= s3_n and state(2) and s1_n and s0_n;         -- 0100
    is_add   <= s3_n and state(2) and s1_n and state(0);     -- 0101
    is_sub   <= s3_n and state(2) and state(1) and s0_n;     -- 0110
    is_lda   <= s3_n and state(2) and state(1) and state(0); -- 0111
    is_write <= state(3) and s2_n and s1_n and s0_n;         -- 1000
    is_stop  <= state(3) and s2_n and s1_n and state(0);     -- 1001

    ---------------------------------------------------------------------------
    -- 3) Opcode decode: AND-gate products of opcode bits
    --    opcode(3) is '0' for all valid instructions, decoded via bits 2:0.
    ---------------------------------------------------------------------------
    op_lda <= not opcode(3) and not opcode(2) and not opcode(1) and not opcode(0); -- 0000
    op_sto <= not opcode(3) and not opcode(2) and not opcode(1) and     opcode(0); -- 0001
    op_add <= not opcode(3) and not opcode(2) and     opcode(1) and not opcode(0); -- 0010
    op_sub <= not opcode(3) and not opcode(2) and     opcode(1) and     opcode(0); -- 0011
    op_stp <= not opcode(3) and     opcode(2) and     opcode(1) and     opcode(0); -- 0111

    -- Memory-access opcodes (ADD, SUB, or LDA)
    op_mem <= op_add or op_sub or op_lda;

    -- Jump-taken condition:
    --   JMP = opcode "0100" (unconditional)
    --   JGE = opcode "0101" AND acc_15='0'  (ACC >= 0)
    --   JNE = opcode "0110" AND acc_z ='0'  (ACC /= 0)
    jmp_taken <= (not opcode(3) and     opcode(2) and not opcode(1) and not opcode(0))                    or
                 (not opcode(3) and     opcode(2) and not opcode(1) and     opcode(0) and not acc_15)      or
                 (not opcode(3) and     opcode(2) and     opcode(1) and not opcode(0) and not acc_z);

    ---------------------------------------------------------------------------
    -- 4) Next-state logic functions
    --    One boolean equation per state-register bit.
    --
    --    Transition table (current -> next):
    --      FETCH  + STP            -> STOP  (1001)
    --      FETCH  + jmp_taken      -> JMP   (0010)
    --      FETCH  + else           -> INC   (0001)
    --      INC    + STO            -> STO   (0011)
    --      INC    + mem_op         -> READ  (0100)
    --      INC    + else           -> FETCH (0000)
    --      JMP                     -> FETCH (0000)
    --      STO                     -> FETCH (0000)
    --      READ   + ADD            -> ADD   (0101)
    --      READ   + SUB            -> SUB   (0110)
    --      READ   + LDA            -> LDA   (0111)
    --      READ   + else           -> FETCH (0000)
    --      ADD / SUB / LDA         -> WRITE (1000)
    --      WRITE                   -> FETCH (0000)
    --      STOP                    -> FETCH (0000)
    ---------------------------------------------------------------------------

    -- next0 = '1' for targets: INC(0001), STO(0011), ADD(0101), LDA(0111), STOP(1001)
    next0 <= (is_fetch and not op_stp and not jmp_taken)  or  -- -> INC  (0001)
             (is_inc   and op_sto)                        or  -- -> STO  (0011)
             (is_read  and op_add)                        or  -- -> ADD  (0101)
             (is_read  and op_lda)                        or  -- -> LDA  (0111)
             (is_fetch and op_stp);                           -- -> STOP (1001)

    -- next1 = '1' for targets: JMP(0010), STO(0011), SUB(0110), LDA(0111)
    next1 <= (is_fetch and not op_stp and jmp_taken)      or  -- -> JMP  (0010)
             (is_inc   and op_sto)                        or  -- -> STO  (0011)
             (is_read  and op_sub)                        or  -- -> SUB  (0110)
             (is_read  and op_lda);                           -- -> LDA  (0111)

    -- next2 = '1' for targets: READ(0100), ADD(0101), SUB(0110), LDA(0111)
    next2 <= (is_inc   and op_mem)                        or  -- -> READ (0100)
             (is_read  and op_add)                        or  -- -> ADD  (0101)
             (is_read  and op_sub)                        or  -- -> SUB  (0110)
             (is_read  and op_lda);                           -- -> LDA  (0111)

    -- next3 = '1' for targets: WRITE(1000), STOP(1001)
    next3 <= (is_add or is_sub or is_lda)                 or  -- -> WRITE(1000)
             (is_fetch and op_stp);                           -- -> STOP (1001)

    ---------------------------------------------------------------------------
    -- 5) State register (the only sequential element)
    ---------------------------------------------------------------------------
    state_reg: process(clk, reset)
    begin
        if reset = '1' then
            state <= "0000";  -- FETCH
        elsif rising_edge(clk) then
            state <= next3 & next2 & next1 & next0;
        end if;
    end process;

    ---------------------------------------------------------------------------
    -- 6) Output logic functions (Moore: depend only on current state)
    --    Each output is a simple OR of state-decode signals.
    --
    --    State     | selA selB ir_ld pc_ld acc_ld acc_oe RnW  alfu_s
    --    ----------+------------------------------------------------
    --    FETCH     |  0    0    1     0      0      0    1     00
    --    INC_PC    |  0    1    0     1      0      0    1     11
    --    JMP       |  0    1    0     1      0      0    1     00
    --    STO       |  1    0    0     0      0      1    0     00
    --    READ_OP   |  1    0    0     0      0      0    1     00
    --    ADD       |  0    0    0     0      0      0    1     10
    --    SUB       |  0    0    0     0      0      0    1     01
    --    LDA       |  0    0    0     0      0      0    1     00
    --    WRITE     |  0    0    0     0      1      0    1     00
    --    STOP      |  0    0    0     0      0      0    1     00
    ---------------------------------------------------------------------------
    selA      <= is_sto or is_read;
    selB      <= is_inc or is_jmp;
    ir_ld     <= is_fetch;
    pc_ld     <= is_inc or is_jmp;
    acc_ld    <= is_write;
    acc_oe    <= is_sto;
    RnW       <= not is_sto;                -- 1=Read, 0=Write (only STO writes)
    alfu_s(1) <= is_add or is_inc;          -- '1' for ALU_ADD="10" and ALU_INC="11"
    alfu_s(0) <= is_sub or is_inc;          -- '1' for ALU_SUB="01" and ALU_INC="11"

end LogicFunctions;