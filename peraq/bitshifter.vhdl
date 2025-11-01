LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY BitShifter IS
    PORT (
        Data_In  : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
        Shift_Ctrl : IN  STD_LOGIC_VECTOR(1 DOWNTO 0); -- 00: No Shift, 01: Shift Left, 10: Shift Right
        Data_Out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        Carry_Out : OUT STD_LOGIC
    );
END BitShifter;

ARCHITECTURE Behavioral OF BitShifter IS
BEGIN
    PROCESS (Data_In, Shift_Ctrl)
    BEGIN
        CASE Shift_Ctrl IS
            WHEN "00" => -- No Shift
                Data_Out <= Data_In;
                Carry_Out <= '0';
            
            WHEN "01" => -- Shift Left
                Data_Out <= Data_In(6 DOWNTO 0) & '0';
                Carry_Out <= Data_In(7);
            
            WHEN "10" => -- Shift Right
                Data_Out <= '0' & Data_In(7 DOWNTO 1);
                Carry_Out <= Data_In(0);
            
            WHEN OTHERS =>
                Data_Out <= (OTHERS => '0');
                Carry_Out <= '0';
        END CASE;
    END PROCESS;
END Behavioral;