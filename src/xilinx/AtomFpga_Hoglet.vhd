--------------------------------------------------------------------------------
-- Copyright (c) 2014 David Banks
--
-- based on work by Alan Daly. Copyright(c) 2009. All rights reserved.
--------------------------------------------------------------------------------
--   ____  ____ 
--  /   /\/   / 
-- /___/  \  /    
-- \   \   \/    
--  \   \         
--  /   /         Filename  : AtomFpga_Hoglet.vhd
-- /___/   /\     Timestamp : 03/04/2014 19:27:00
-- \   \  /  \ 
--  \___\/\___\ 
--
--Design Name: AtomFpga_Hoglet
--Device: spartan3E

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity AtomFpga_Hoglet is
    port (clk_32M00 : in  std_logic;
           ps2_clk  : in  std_logic;
           ps2_data : in  std_logic;
           ps2_mouse_clk  : inout  std_logic;
           ps2_mouse_data : inout  std_logic;
           ERSTn    : in  std_logic;
           red      : out std_logic_vector (2 downto 2);
           green    : out std_logic_vector (2 downto 1);
           blue     : out std_logic_vector (2 downto 2);
           vsync    : out std_logic;
           hsync    : out std_logic;
           audiol   : out std_logic;
           audioR   : out std_logic;
           RAMOEn   : out std_logic;
           RAMWRn   : out std_logic;
           ROMOEn   : out std_logic;
           ROMWRn   : out std_logic;
           ExternA  : out std_logic_vector (16 downto 0);
           ExternD  : inout std_logic_vector (7 downto 0);
           SDMISO   : in  std_logic;
           SDSS     : out std_logic;
           SDCLK    : out std_logic;
           SDMOSI   : out std_logic;
           RxD      : in  std_logic;
           TxD      : out std_logic;
           LED1     : out std_logic;
           LED2     : out std_logic
           );
end AtomFpga_Hoglet;

architecture behavioral of AtomFpga_Hoglet is

    signal clk_vga : std_logic;
    signal clk_16M00 : std_logic;
    signal IRSTn     : std_logic;
    signal Phi2      : std_logic;

    signal RamCE     : std_logic;
    signal RomCE     : std_logic;
    signal ExternWE  : std_logic;
    signal ExternDin : std_logic_vector (7 downto 0);
    signal ExternDout: std_logic_vector (7 downto 0);
    
    signal nARD     : std_logic;
    signal nAWR     : std_logic;
    signal AVRA0    : std_logic;
    signal AVRInt   : std_logic;
    signal AVRDataIn  : std_logic_vector (7 downto 0);
    signal AVRDataOut  : std_logic_vector (7 downto 0);

    signal Addr  : std_logic_vector (16 downto 0);
    signal PL8Data  : std_logic_vector (7 downto 0);
    signal PL8Enable: std_logic;
    signal cpuclken     : std_logic;
    
    signal BFFE_Enable : std_logic;
    signal BFFF_Enable : std_logic;
    
    signal RomJumpers  : std_logic_vector (7 downto 0);
    signal RomLatch  : std_logic_vector (7 downto 0);
    
    signal ExtRAMEN1 : std_logic; -- SwitchLatch[0] on Phill's board
    signal ExtRAMEN2 : std_logic; -- SwitchLatch[1] on Phill's board
    signal DskRAMEN : std_logic; -- SwitchLatch[1] on Phill's board, not currently used in AtomFPGA
    signal DskROMEN : std_logic; -- SwitchLatch[2] on Phill's board
    signal BeebMode : std_logic; -- SwitchLatch[3] on Phill's board

    signal Addr6000RAM : std_logic;
    signal Addr6000ROM : std_logic;
    signal Addr7000RAM : std_logic;
    signal Addr7000ROM : std_logic;
    signal AddrA000RAM : std_logic;
    signal AddrA000ROM : std_logic;

    signal avr_TxR : std_logic;
    
    signal uart_RxD : std_logic;
    signal uart_TxD : std_logic;     
    
begin

    inst_dcm4 : entity work.dcm4 port map(
        CLKIN_IN  => clk_32M00,
        CLK0_OUT  => open,
        CLKFX_OUT => clk_vga
    );

    inst_dcm5 : entity work.dcm5 port map(
        CLKIN_IN  => clk_32M00,
        CLKFX_OUT => clk_16M00
    );
    
    inst_AtomFpga_Core : entity work.AtomFpga_Core
    generic map (
        CImplSDDOS => false,
        CImplGraphicsExt => true,
        CImplSoftChar    => true,
        CImplSID         => true,
        CImplVGA80x40    => true,
        CImplHWScrolling => true,
        CImplMouse       => true,
        CImplUart        => true,
        CImplDoubleVideo => false,
        MainClockSpeed   => 16000000,
        DefaultBaud      => 115200          
     )
     port map(
        clk_vga   => clk_vga,
        clk_16M00 => clk_16M00,
        clk_32M00 => clk_32M00,
        ps2_clk   => ps2_clk,
        ps2_data  => ps2_data,
        ps2_mouse_clk   => ps2_mouse_clk,
        ps2_mouse_data  => ps2_mouse_data,
        ERSTn     => ERSTn,
        IRSTn     => IRSTn,
        red(2)   => red(2),
        red(1 downto 0)    => open,
        green(2 downto 1) => green(2 downto 1),
        green(0)  => open,
        blue(2)  => blue(2),
        blue(1 downto 0) => open,
        vsync     => vsync,
        hsync     => hsync,
        RamCE     => open,
        RomCE     => open,
        Phi2      => Phi2,
        ExternWE  => ExternWE,
        ExternA   => Addr,
        ExternDin => ExternDin,
        ExternDout=> ExternDout,        
        audiol    => audiol,
        audioR    => audioR,
        SDMISO    => '0',
        SDSS      => open,
        SDCLK     => open,
        SDMOSI    => open,
        uart_RxD  => uart_RxD,
        uart_TxD  => uart_TxD,
        LED1      => open,
        LED2      => open,
        charSet   => '0'
        );  

    Inst_AVR8: entity work.AVR8 port map(
        clk16M      => clk_16M00,
        nrst        => IRSTn,
        portain     => AVRDataOut,
        portaout    => AVRDataIn,

        portbin(0)  => '0',
        portbin(1)  => '0',
        portbin(2)  => '0',
        portbin(3)  => '0',
        portbin(4)  => AVRInt,
        portbin(5)  => '0',
        portbin(6)  => '0',
        portbin(7)  => '0',
        
        portbout(0)  => nARD,
        portbout(1)  => nAWR,
        portbout(2)  => open,
        portbout(3)  => AVRA0,
        portbout(4)  => open,
        portbout(5)  => open,
        portbout(6)  => LED1,
        portbout(7)  => LED2,

        portdin      => (others => '0'),
        portdout(0)  => open,
        portdout(1)  => open,
        portdout(2)  => open,
        portdout(3)  => open,
        portdout(4)  => SDSS,
        portdout(5)  => open,
        portdout(6)  => open,
        portdout(7)  => open,
        
        -- AtoMMC IO Port (Joystick)
        portein      => (others => '1'),
        porteout     => open,

        spi_mosio    => SDMOSI,
        spi_scko     => SDCLK,
        spi_misoi    => SDMISO,
     
        rxd          => RxD,
        txd          => avr_TxR
    );
    
    Inst_AtomPL8: entity work.AtomPL8 port map(
        clk => clk_16M00,
        enable => PL8Enable,
        nRST => IRSTn,
        RW => not ExternWE,
        Addr => Addr(2 downto 0),
        DataIn => ExternDin,
        DataOut => PL8Data,
        AVRDataIn => AVRDataIn,
        AVRDataOut => AVRDataOut,
        nARD => nARD,
        nAWR => nAWR,
        AVRA0 => AVRA0,
        AVRINTOut => AVRInt,
        AtomIORDOut => open,
        AtomIOWROut => open
    );

    Addr6000ROM <= '1' when Addr(15 downto 12) = "0110" and (BeebMode = '1' and (RomLatch(4 downto 0) /= "00000" or ExtRAMEN1 = '0'))
                       else '0';

    Addr6000RAM <= '1' when Addr(15 downto 12) = "0110" and (BeebMode = '0' or (RomLatch(4 downto 0) = "00000" and ExtRAMEN1 = '1'))
                       else '0';

    Addr7000ROM <= '1' when Addr(15 downto 12) = "0111" and (BeebMode = '1' and ExtRAMEN2 = '0')
                       else '0';

    Addr7000RAM <= '1' when Addr(15 downto 12) = "0111" and (BeebMode = '0' or ExtRAMEN2 = '1')
                       else '0';
        
    AddrA000ROM <= '1' when Addr(15 downto 12) = "1010" and (BeebMode = '1' or RomLatch(4 downto 0) /= "00000" or ExtRAMEN1 = '0')
                       else '0';

    AddrA000RAM <= '1' when Addr(15 downto 12) = "1010" and (BeebMode = '0' and RomLatch(4 downto 0) = "00000" and ExtRAMEN1 = '1')
                       else '0';
    
    RamCE       <= '1' when Addr(15 downto 12) < "0110" or Addr6000RAM = '1' or Addr7000RAM = '1' or AddrA000RAM = '1'
                       else '0';

    RomCE       <= '1' when Addr(15 downto 14) = "11" or Addr6000ROM = '1' or Addr7000ROM = '1' or AddrA000ROM = '1'
                       else '0';
           
    RAMWRn     <= not (ExternWE and RamCE and Phi2);
    RAMOEn     <= not ((not ExternWE) and RamCE);

    ROMWRn     <= not (ExternWE and RomCE and Phi2);
    ROMOEn     <= not ((not ExternWE) and RomCE);

    ExternD    <= ExternDin when ExternWE = '1' else "ZZZZZZZZ";
    
    PL8Enable  <= '1' when Addr(15 downto 8) = "10110100" else '0';
    
    ExternDout <= PL8Data when PL8Enable = '1' else
                  RomJumpers when BFFE_Enable = '1' else 
                  RomLatch when BFFF_Enable = '1' else 
                  ExternD;

    -------------------------------------------------
    -- External address decoding
    -------------------------------------------------

    ExternA  <=

        -- 0x6000 comes from ROM address 0x08000-0x0F000 in Beeb Mode (Ext ROM 1)
        ( "01" & RomLatch(2 downto 0) & Addr(11 downto 0)) when Addr6000ROM = '1' else
    
        -- 0x6000 is 4K remappable RAM bank mapped to 0x6000
        (ExtRAMEN1 & Addr(15 downto 0)) when Addr6000RAM = '1' else
        
        -- 0x7000 comes from ROM address 0x19000 in Beeb Mode (Ext ROM 2)
        ( "11001" & Addr(11 downto 0)) when Addr7000ROM = '1' else
    
        -- 0x7000 is 4K remappable RAM bank mapped to 0x7000
        (ExtRAMEN2 & Addr(15 downto 0)) when Addr7000RAM = '1' else

        -- 0xA000 remappable RAM bank at 0x7000 re-mapped to 0xA000
        ( "00111" & Addr(11 downto 0)) when AddrA000RAM = '1' else
        
        -- 0xA000 is bank switched by ROM Latch in Atom Mode
        -- 5 bits of RomLatch are used here, to allow any of the 32 pages of FLASH to A000 for in system programming
        ( RomLatch(4 downto 0) & Addr(11 downto 0)) when AddrA000ROM = '1' and BeebMode = '0' else

        -- 0xA000 comes from ROM address 0x0A000 in Beeb Mode
        ( "11010" & Addr(11 downto 0)) when AddrA000ROM = '1' and BeebMode = '1' else

        -- 0xC000-0xFFFF comes from ROM address 0x1C000-0x1FFFF in Beeb Mode
        ( "1" & Addr(15 downto 0)) when Addr(15 downto 14) = "11" and BeebMode = '1' else
        
        -- 0xC000-0xFFFF comes from ROM address 0x10000-0x17FFF in Atom Mode (2x 16K banks selected SwitchLatch[2])
        ( "10" & DskROMEN & Addr(13 downto 0)) when Addr(15 downto 14) = "11" and BeebMode = '0' else
             
        -- RAM
        Addr;

    -------------------------------------------------
    -- ROM Latch and Jumpers
    -------------------------------------------------
    BFFE_Enable <= '1' when Addr(15 downto 0) = "1011111111111110" else '0';
    BFFF_Enable <= '1' when Addr(15 downto 0) = "1011111111111111" else '0';

    ExtRAMEN1 <= RomJumpers(0);
    ExtRAMEN2 <= RomJumpers(1);
    DskRAMEN <= RomJumpers(1); -- currently unused
    DskROMEN <= RomJumpers(2);
    BeebMode <= RomJumpers(3);
        
    RomLatchProcess : process (ERSTn, IRSTn, clk_16M00)
    begin
        if ERSTn = '0' then
            RomJumpers <= "00000000";
            RomLatch   <= "00000000";
        elsif rising_edge(clk_16M00) then
            if BFFE_Enable = '1' and ExternWE = '1' then
                RomJumpers <= ExternDin;
            end if;
            if BFFF_Enable = '1' and ExternWE = '1' then
                RomLatch   <= ExternDin;
            end if;
        end if;
    end process;
    
    uart_RxD <= RxD;
    -- Idle state is high, logically OR the active low signals
    TxD <= uart_TxD and avr_TxR;
    
    
end behavioral;

