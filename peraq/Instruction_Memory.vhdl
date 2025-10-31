LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE STD.TEXTIO.ALL;         
USE IEEE.STD_LOGIC_TEXTIO.ALL; 

ENTITY Instruction_Memory IS
    PORT (
        Address  : IN  UNSIGNED(7 DOWNTO 0);
        Data_Out : OUT STD_LOGIC_VECTOR(23 DOWNTO 0)
    );
END Instruction_Memory;

ARCHITECTURE Behavioral_FromFile OF Instruction_Memory IS
    CONSTANT ROM_FILENAME : STRING := "binary.txt";
    TYPE rom_type IS ARRAY(0 TO 255) OF STD_LOGIC_VECTOR(23 DOWNTO 0);

    IMPURE FUNCTION init_rom_from_file (file_name : STRING) RETURN rom_type IS
        FILE rom_file     : TEXT OPEN READ_MODE IS file_name;
        VARIABLE line_rd  : LINE;
        VARIABLE rom_data : rom_type;
        VARIABLE byte_opc : STD_LOGIC_VECTOR(7 DOWNTO 0);
        VARIABLE byte_op1 : STD_LOGIC_VECTOR(7 DOWNTO 0);
        VARIABLE byte_op2 : STD_LOGIC_VECTOR(7 DOWNTO 0);

    BEGIN
        rom_data := (OTHERS => (OTHERS => '0'));

        FOR i IN 0 TO 255 LOOP
            IF ENDFILE(rom_file) THEN
                EXIT;
            END IF;

            READLINE(rom_file, line_rd);
            READ(line_rd, byte_opc);

            IF ENDFILE(rom_file) THEN EXIT; END IF;
            READLINE(rom_file, line_rd);
            READ(line_rd, byte_op1);

            IF ENDFILE(rom_file) THEN EXIT; END IF; 
            READLINE(rom_file, line_rd);
            READ(line_rd, byte_op2); 

            rom_data(i) := byte_opc & byte_op1 & byte_op2;

        END LOOP;

        FILE_CLOSE(rom_file);
        RETURN rom_data;

    END init_rom_from_file;

    SIGNAL ROM_PROGRAM : rom_type := init_rom_from_file(ROM_FILENAME);

BEGIN

    Data_Out <= ROM_PROGRAM(TO_INTEGER(Address));

END Behavioral_FromFile;