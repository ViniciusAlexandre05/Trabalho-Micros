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

    -- Processo comportamental que calcula tudo
    process (Data_In, Shift_Ctrl)
        -- Variáveis são usadas para cálculos internos
        variable temp_data_out : std_logic_vector(7 downto 0);
        variable temp_carry_out : std_logic;
        variable temp_parity : std_logic;
        variable temp_flags : std_logic_vector(3 downto 0);
    begin
    
        -- 1. Lógica do Shifter (Shift)
        case Shift_Ctrl is
            when "01" => -- Shift Left (SHL)
                temp_data_out := Data_In(6 DOWNTO 0) & '0';
                temp_carry_out := Data_In(7);
            
            when "10" => -- Shift Right (SHR)
                temp_data_out := '0' & Data_In(7 DOWNTO 1);
                temp_carry_out := Data_In(0);
            
            when others => -- Inclui "00" (No Shift)
                temp_data_out := Data_In;
                temp_carry_out := '0';
        end case;
        
        -- 2. Lógica dos Flags
        
        -- Cálculo da Paridade (Even Parity)
        temp_parity := '0';
        for i in 0 to 7 loop
            temp_parity := temp_parity XOR temp_data_out(i);
        end loop;
        
        -- Atribuição dos Flags
        if UNSIGNED(temp_data_out) = 0 then
            temp_flags(3) := '1'; -- ZF
        else
            temp_flags(3) := '0';
        end if;
        
        temp_flags(2) := temp_data_out(7); -- SF
        temp_flags(1) := not temp_parity;  -- PF
        temp_flags(0) := temp_carry_out;   -- CF

        -- 3. Atribuição das Saídas
        Data_Out <= temp_data_out;
        shf_flags_out <= temp_flags;
        
    end process;

END behavioral;