library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity seven_segment_driver is
    Port (
        clk      : in  STD_LOGIC;
        reset    : in  STD_LOGIC;
        data_in  : in  STD_LOGIC_VECTOR(15 downto 0);
        seg      : out STD_LOGIC_VECTOR(6 downto 0);
        an       : out STD_LOGIC_VECTOR(3 downto 0)
    );
end seven_segment_driver;

architecture Behavioral of seven_segment_driver is
    signal clk_div : unsigned(15 downto 0) := (others => '0');
    signal scan_clk : std_logic;
    signal digit_sel : unsigned(1 downto 0) := "00";
    signal current_digit : std_logic_vector(3 downto 0);
begin

    -- Clock divider for multiplexing (approx 760Hz for 50MHz clock)
    process(clk, reset)
    begin
        if reset = '1' then
            clk_div <= (others => '0');
        elsif rising_edge(clk) then
            clk_div <= clk_div + 1;
        end if;
    end process;
    
    scan_clk <= clk_div(15);

    -- Digit selector counter
    process(scan_clk, reset)
    begin
        if reset = '1' then
            digit_sel <= "00";
        elsif rising_edge(scan_clk) then
            digit_sel <= digit_sel + 1;
        end if;
    end process;

    -- Multiplexer for data
    process(digit_sel, data_in)
    begin
        case digit_sel is
            when "00" => current_digit <= data_in(3 downto 0);
            when "01" => current_digit <= data_in(7 downto 4);
            when "10" => current_digit <= data_in(11 downto 8);
            when "11" => current_digit <= data_in(15 downto 12);
            when others => current_digit <= "0000";
        end case;
    end process;

    -- Anode decoder (Active Low)
    process(digit_sel)
    begin
        case digit_sel is
            when "00" => an <= "1110"; -- Rightmost digit
            when "01" => an <= "1101";
            when "10" => an <= "1011";
            when "11" => an <= "0111"; -- Leftmost digit
            when others => an <= "1111";
        end case;
    end process;

    -- Hex to 7-segment decoder (Active Low segments for Common Anode)
    process(current_digit)
    begin
        case current_digit is
            when "0000" => seg <= "1000000"; -- 0
            when "0001" => seg <= "1111001"; -- 1
            when "0010" => seg <= "0100100"; -- 2
            when "0011" => seg <= "0110000"; -- 3
            when "0100" => seg <= "0011001"; -- 4
            when "0101" => seg <= "0010010"; -- 5
            when "0110" => seg <= "0000010"; -- 6
            when "0111" => seg <= "1111000"; -- 7
            when "1000" => seg <= "0000000"; -- 8
            when "1001" => seg <= "0010000"; -- 9
            when "1010" => seg <= "0001000"; -- A
            when "1011" => seg <= "0000011"; -- b
            when "1100" => seg <= "1000110"; -- C
            when "1101" => seg <= "0100001"; -- d
            when "1110" => seg <= "0000110"; -- E
            when "1111" => seg <= "0001110"; -- F
            when others => seg <= "1111111";
        end case;
    end process;

end Behavioral;
