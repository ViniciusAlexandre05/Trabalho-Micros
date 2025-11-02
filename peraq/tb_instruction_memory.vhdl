LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY tb_instruction_memory IS
END tb_instruction_memory;

ARCHITECTURE Behavioral OF tb_instruction_memory IS

    -- Component Declaration
    COMPONENT Instruction_Memory
        PORT (
            Address  : IN  UNSIGNED(7 DOWNTO 0);
            Data_Out : OUT STD_LOGIC_VECTOR(17 DOWNTO 0)
        );
    END COMPONENT;

    -- Sinais de teste
    SIGNAL Address  : UNSIGNED(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL Data_Out : STD_LOGIC_VECTOR(17 DOWNTO 0);

    function to_string(slv : std_logic_vector) return string is
        variable result : string(1 to slv'length);
    begin
        for i in slv'range loop
            case slv(i) is
                when '0' => result(i - slv'low + 1) := '0';
                when '1' => result(i - slv'low + 1) := '1';
                when others => result(i - slv'low + 1) := 'X';
            end case;
        end loop;
        return result;
    end function;

BEGIN

    -- Instancia a unidade sob teste (UUT)
    UUT: Instruction_Memory
        PORT MAP (
            Address  => Address,
            Data_Out => Data_Out
        );

    -- Processo de estímulo
    Stimulus: PROCESS
    BEGIN
        -- Endereço 0: MOV R1, #xAA
        Address <= x"00";
        WAIT FOR 10 ns;
        REPORT "Addr=0 | Data_Out=" & to_string(Data_Out);

        -- Endereço 1: MOV R2, #xBB
        Address <= x"01";
        WAIT FOR 10 ns;
        REPORT "Addr=1 | Data_Out=" & to_string(Data_Out);

        -- Endereço 2: ADD R1, R2
        Address <= x"02";
        WAIT FOR 10 ns;
        REPORT "Addr=2 | Data_Out=" & to_string(Data_Out);

        -- Endereço 3: SHL R1
        Address <= x"03";
        WAIT FOR 10 ns;
        REPORT "Addr=3 | Data_Out=" & to_string(Data_Out);

        -- Endereço 4: HALT
        Address <= x"04";
        WAIT FOR 10 ns;
        REPORT "Addr=4 | Data_Out=" & to_string(Data_Out);

        -- Endereço 10 (deve ser NOP)
        Address <= x"0A";
        WAIT FOR 10 ns;
        REPORT "Addr=10 | Data_Out=" & to_string(Data_Out);

        -- Fim do teste
        WAIT;
    END PROCESS;

END Behavioral;
