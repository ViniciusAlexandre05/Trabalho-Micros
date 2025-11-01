library IEEE;
use IEEE.std_logic_1164.all;

entity Flag_Register is
    port (
        clk     : in  std_logic;              -- Clock (síncrono)
        rst     : in  std_logic;              -- Reset síncrono
        
        -- Porta de LOAD(ENABLE)
        LD_ZF   : in  std_logic;              -- Load Zero Flag
        LD_CF   : in  std_logic;              -- Load Carry Flag
        LD_SF   : in  std_logic;              -- Load Sign Flag
        LD_PF   : in  std_logic;              -- Load Parity Flag
        LD_IF   : in  std_logic;              -- Load Interrupt Flag
        LD_DF   : in  std_logic;              -- Load Direction Flag
        LD_OF   : in  std_logic;              -- Load Overflow Flag
        
        -- Portas de DADOS
        set_ZF  : in  std_logic;              -- Zero Flag
        set_CF  : in  std_logic;              -- Carry Flag
        set_SF  : in  std_logic;              -- Sign Flag
        set_PF  : in  std_logic;              -- Parity Flag
        set_IF  : in  std_logic;              -- Interrupt Flag
        set_DF  : in  std_logic;              -- Direction Flag
        set_OF  : in  std_logic;              -- Overflow Flag
        
        R_FLAGS : out std_logic_vector(6 downto 0) -- Saída do registrador
    );
end Flag_Register;

architecture Behavioral of Flag_Register is
    -- Mapeamento dos bits:
    -- (6) ZF, (5) CF, (4) SF, (3) PF, (2) IF, (1) DF, (0) OF
    signal flags_s : std_logic_vector(6 downto 0) := (others => '0');
begin
    process(clk)
    begin
        if falling_edge(clk) then
            if rst = '1' then
                flags_s <= (others => '0');  -- Reset síncrono zera todos os flags
            else
                -- Lógica de Escrita Seletiva:
                -- Cada flag só é atualizado se seu load estiver em '1'
                
                -- Zero Flag (ZF): Bit 6
                if LD_ZF = '1' then flags_s(6) <= set_ZF; end if;
                
                -- Carry Flag (CF): Bit 5
                if LD_CF = '1' then flags_s(5) <= set_CF; end if;
                
                -- Sign Flag (SF): Bit 4
                if LD_SF = '1' then flags_s(4) <= set_SF; end if;
                
                -- Parity Flag (PF): Bit 3
                if LD_PF = '1' then flags_s(3) <= set_PF; end if;
                
                -- Interrupt Flag (IF): Bit 2
                if LD_IF = '1' then flags_s(2) <= set_IF; end if;
                
                -- Direction Flag (DF): Bit 1
                if LD_DF = '1' then flags_s(1) <= set_DF; end if;
                
                -- Overflow Flag (OF): Bit 0
                if LD_OF = '1' then flags_s(0) <= set_OF; end if;
                
            end if;
        end if;
    end process;

    -- Passa os flags para a saída
    R_FLAGS <= flags_s;
end Behavioral;