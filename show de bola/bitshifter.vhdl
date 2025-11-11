LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY BitShifter IS
    PORT (
        Data_In    : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
        Shift_Ctrl : IN  STD_LOGIC_VECTOR(1 DOWNTO 0); 
        Data_Out   : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        shf_flags_out : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
    );
END BitShifter;

ARCHITECTURE behavioral OF BitShifter IS
BEGIN
    process (Data_In, Shift_Ctrl)
        variable temp_data_out : std_logic_vector(7 downto 0);
        variable temp_carry_out : std_logic;
        variable temp_parity : std_logic;
        variable temp_flags : std_logic_vector(3 downto 0);

    begin
        case Shift_Ctrl is
            when "01" => --SHL
                temp_data_out := Data_In(6 DOWNTO 0) & '0';
                temp_carry_out := Data_In(7);
            
            when "10" => -- SHR
                temp_data_out := '0' & Data_In(7 DOWNTO 1);
                temp_carry_out := Data_In(0);
            
            when others => -- Nada
                temp_data_out := Data_In;
                temp_carry_out := '0';
        end case;
        
        -- paridade
        temp_parity := '0';
        for i in 0 to 7 loop
            temp_parity := temp_parity XOR temp_data_out(i);
        end loop;
        
        if UNSIGNED(temp_data_out) = 0 then -- zero
            temp_flags(3) := '1';
        else
            temp_flags(3) := '0';
        end if;
        
        temp_flags(2) := temp_data_out(7); -- sinal
        temp_flags(1) := not temp_parity;  -- paridade
        temp_flags(0) := temp_carry_out;   -- carry

        Data_Out <= temp_data_out;
        shf_flags_out <= temp_flags;
        
    end process;

END behavioral;