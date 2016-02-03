------------------------------------------------------------------------------
-- main
--
-- Description:
--   The main system to run the mouse
--
--
-- Authors:
--    
--  o Name:    Matthew Rodusek 
--    ID:      120184140
--    Contact: rodu4140@mylaurier.ca
--  
--  o Name:    Brandon Smith 
--    ID:      120201510
--    Contact: smit1510@mylaurier.ca
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.seg7_pkg.all;
use work.bcd_pkg.all;
use work.sync_pkg.all;
use work.pixel_rom_pkg.all;
use work.mouse_driver_pkg.all;

entity main is

	-- Inputs / Outputs -------------------------------------------------------
	port(
		-- General Inputs ------------------------------------------------------
		reset       : in std_logic; -- Reset signal
		clock_27mhz : in std_logic; -- 27mhz VGA clock
		clock_50mhz : in std_logic; -- 50mhz FPGA clock
		
		mode     : in std_logic_vector(1 downto 0); -- 00 enabled, 01 standby, 10 triggered 
		out_mode : out std_logic_vector(1 downto 0);-- send a change in mode out
		-- Ultrasonic Data -----------------------------------------------------
		trigger     : in std_logic; -- Trigger signal to ultrasonic sensor
		echo        : in std_logic; -- Echo signal from ultrasonic sensor
		echo_7seg   : out std_logic_vector(20 downto 0); -- 7 segment output
		trigger_led : out std_logic;
		echo_led    : out std_logic;
		
		-- Mouse Input ---------------------------------------------------------
		mouse_data   : inout std_logic; -- Data coming from the mouse
      mouse_clk    : inout std_logic;  -- Clock from the mouse
		
		-- VGA Output ----------------------------------------------------------
		vga_clock    : out std_logic; -- clock for the DAC
		vga_hs       : out std_logic; -- signal for horizontal sync
		vga_vs       : out std_logic; -- signal for vertical sync
		vga_sync_out : out std_logic; -- signal for VGA_SYNC on DAC
		vga_blank    : out std_logic; -- signal for VGA_BLANK on DAC
		vga_r        : out std_logic_vector(9 downto 0); -- DAC red component encoding
		vga_g        : out std_logic_vector(9 downto 0); -- DAC green component encoding
		vga_b        : out std_logic_vector(9 downto 0)  -- DAC blue component encoding
	);

end entity main;

------------------------------------------------------------------------------

architecture behavior of main is

	-- Signals ---------------------------------------------------------------
	type state_type is (
		standby,  -- Wait for the trigger signal to send
		enabled,  -- Wait for the rising-edge of echo
		triggered -- Wait for the falling-edge of echo
	);
	
	signal current_state : state_type := standby;

	-- Ultrasonic -------------------------------------------------------------
	signal distance_data : std_logic_vector(7 downto 0); 
	signal bcd_out       : std_logic_Vector(11 downto 0);
	
	component ultrasonic_sensor is
		-- Generics ------------------------------------------------------------
		generic(
			frequency : natural := 50000000; -- Clock frequency (hz)
			max_cm    : natural := 10;      -- Max distance (in cm)
			out_bits  : natural := 8        -- Number of output bits
		);

		-- Inputs / Outputs ----------------------------------------------------
		port(
			reset   : in std_logic; -- Reset for state machine
			clk     : in std_logic; -- Clock for state machine
			trigger : in std_logic; -- Trigger signal 
			echo    : in std_logic; -- 
			dataout : out std_logic_vector( out_bits-1 downto 0 ) := (others => '0')
		);
	end component ultrasonic_sensor;

	---------------------------------------------------------------------------
	-- Mouse Handling
	---------------------------------------------------------------------------
	
	signal mouse_cursor_row    : std_logic_vector(9 downto 0); -- The row of the current active pixel
	signal mouse_cursor_column : std_logic_vector(9 downto 0); -- The column of the current active pixel
	signal left_button		   : std_logic; --  
	signal right_button        : std_logic; --
	

	---------------------------------------------------------------------------
	-- VGA signals 
	---------------------------------------------------------------------------
	
	signal vga_row        : std_logic_vector(9 downto 0); -- The row of the current active pixel
	signal vga_column     : std_logic_vector(9 downto 0); -- The column of the current active pixel
	signal vga_foreground : std_logic_vector( 2 downto 0 ) := "111"; -- The color of the VGA foreground
	signal vga_background : std_logic_vector( 2 downto 0 ) := "000"; -- The color of the VGA background
	signal vga_button_one : std_logic_vector( 2 downto 0 ) := "100"; -- The color of the first button
	signal vga_button_two : std_logic_vector( 2 downto 0 ) := "110"; -- The color of the second button
	signal vga_button_three : std_logic_vector( 2 downto 0 ) := "010"; -- The color of the third button
	signal vga_graph_colour : std_logic_vector( 2 downto 0 ) := "011"; -- The color of the third button
	signal cursor_colour  : std_logic_vector( 2 downto 0 ) := "111"; -- colour of the cursor
	signal vga_color      : std_logic_vector( 2 downto 0 );
	
	---------------------------------------------------------------------------
	-- ROM Memory
	---------------------------------------------------------------------------
	
	component char_rom_reader is
		port(	
			character_address	 : in	std_logic_vector(5 downto 0);
			font_row, font_col : in std_logic_vector(2 downto 0);
			clock					 : in std_logic;
			rom_mux_output		 : out std_logic
		);		
	end component char_rom_reader;

	signal char_address : std_logic_vector(5 downto 0); -- character address
	signal char_row     : std_logic_vector(2 downto 0); -- Pixel row number
	signal char_col     : std_logic_vector(2 downto 0); -- Pixel col number
	signal char_pixel   : std_logic;                    -- Pixel at the row,col

begin

	process( mode )
	begin
		case current_state is 
			-------------------------------------------------------------
			when standby =>
				if mode = "01" then
					current_state <= enabled;
				else
					current_state <= standby;
				end if;
			-------------------------------------------------------------
			when enabled =>
				if mode = "10" then
					current_state <= triggered;
				elsif mode = "00" then
					current_state <= standby;
				else
					current_state <= enabled;
				end if;
			-------------------------------------------------------------
			when triggered =>
				if mode = "00" then
					current_state <= standby;
				elsif mode = "01" then
					current_state <= enabled;
				else
					current_state <= triggered;
				end if;
			-------------------------------------------------------------
			end case;	
	end process;

	--current_state <= triggered when mode = "10" else
	--					  enabled when mode = "01" else
	--					  standby;

	---------------------------------------------------------------------------
	-- Handle Ultrasonic Sensor
	---------------------------------------------------------------------------
		
	trigger_led <= trigger;
	echo_led    <= echo;

	US: ultrasonic_sensor 
		generic map( 50000000, 20, 8 ) 
		port map( '1', clock_50mhz, trigger, echo, distance_data );

	-- Convert to BCD
	BCD_CONV: bin_to_bcd generic map( 8, 3 ) port map( distance_data, bcd_out );

	SEG7_1: bin4toseg7 port map ( bcd_out(11 downto 8), echo_7seg(20 downto 14) );
	SEG7_2: bin4toseg7 port map ( bcd_out(7 downto 4),  echo_7seg(13 downto 7) );
	SEG7_3: bin4toseg7 port map ( bcd_out(3 downto 0),  echo_7seg(6 downto 0) );
	
	---------------------------------------------------------------------------
	-- Handle Mouse Input
	---------------------------------------------------------------------------
	
	MOUSE_LABEL: mouse_driver port map(clock_50Mhz, reset, mouse_data, mouse_clk, left_button, right_button, mouse_cursor_row, mouse_cursor_column);

	---------------------------------------------------------------------------
	-- Handle VGA Output
	---------------------------------------------------------------------------
	
	vga_clock    <= clock_27mhz;
	vga_sync_out <= '0'; 

	VGA_LABEL: vga_sync
		port map( clock_27mhz, vga_hs, vga_vs, vga_blank, vga_row, vga_column );
		
	PIXEL: pixel_rom 
		port map( vga_color, vga_r, vga_g, vga_b );
		
	---------------------------------------------------------------------------
	-- ROM Memory
	---------------------------------------------------------------------------

	ROM_LABEL: char_rom_reader 
		port map( char_address, char_row, char_col, clock_50mhz, char_pixel );
		
	-- Determine current color of vga text from state
	process( current_state )
	begin
		if( current_state = triggered ) then
			vga_foreground <= "100"; -- Red Text
			vga_background <= "000"; -- Black Background
			vga_button_one <= "100";
			vga_button_two <= "110";
			vga_button_three <= "010";
			cursor_colour  <= "111";
		elsif( current_state = enabled ) then
			vga_foreground <= "110"; -- Yellow Text
			vga_background <= "000"; -- Black Background
			vga_button_one <= "100";
			vga_button_two <= "110";
			vga_button_three <= "010";
			cursor_colour  <= "111";
		else
			vga_foreground <= "010"; -- Green Text
			vga_background <= "000"; -- Black Background
			vga_button_one <= "100";
			vga_button_two <= "110";
			vga_button_three <= "010";
			cursor_colour  <= "111";
			end if;
	end process;
	
	-- Determine row/col of the expected pixel
	process( vga_row, vga_column, current_state )
	begin
		
		if( (vga_row >= 20) and (vga_row < 28) ) then
			char_row <= std_logic_vector(to_unsigned( (conv_integer(vga_row) - 20) ,3));
			
			if( (vga_column >= 284) and (vga_column < 292) ) then    -- char 1: 'E', 'S', 'T'
				if( current_state = enabled ) then
					char_address <= "000101"; -- 05
				elsif( current_state = standby ) then
					char_address <= "010011"; -- 23
				elsif( current_state = triggered ) then
					char_address <= "010100"; -- 24
			end if;
				
				char_col <= std_logic_vector(to_unsigned(conv_integer(vga_column) - 292,3));
			elsif( (vga_column >= 292) and (vga_column < 300) ) then -- char 2: 'N', 'T', 'R'
				if( current_state = enabled ) then
					char_address <= "001110"; -- 16
				elsif( current_state = standby ) then
					char_address <= "010100"; -- 24
				elsif( current_state = triggered ) then
					char_address <= "010010"; -- 22
				end if;
				
				char_col <= std_logic_vector(to_unsigned(conv_integer(vga_column) - 300,3));
			elsif( (vga_column >= 300) and (vga_column < 308) ) then -- char 3: 'A', 'A', 'I'
				if( current_state = enabled ) then
					char_address <= "000001"; -- 01
				elsif( current_state = standby ) then
					char_address <= "000001"; -- 01
				elsif( current_state = triggered ) then
					char_address <= "001001"; -- 11
				end if;
				
				char_col <= std_logic_vector(to_unsigned(conv_integer(vga_column) - 308,3));
			elsif( (vga_column >= 308) and (vga_column < 316) ) then -- char 4: 'B', 'N', 'G'
				if( current_state = enabled ) then
					char_address <= "000010"; -- 02
				elsif( current_state = standby ) then
					char_address <= "001110"; -- 16
				elsif( current_state = triggered ) then
					char_address <= "000111"; -- 07
				end if;
				
				char_col <= std_logic_vector(to_unsigned(conv_integer(vga_column) - 316,3));
			elsif( (vga_column >= 316) and (vga_column < 324) ) then -- char 5: 'L', 'D', 'G'
				if( current_state = enabled ) then
					char_address <= "001100"; -- 14
				elsif( current_state = standby ) then
					char_address <= "000100"; -- 04
				elsif( current_state = triggered ) then
					char_address <= "000111"; -- 07
				end if;
				
				char_col <= std_logic_vector(to_unsigned(conv_integer(vga_column) - 324,3));
			elsif( vga_column >= 324 and vga_column < 332 ) then -- char 6: 'E', 'B', 'E'
				if( current_state = enabled ) then
					char_address <= "000101"; -- 05
				elsif( current_state = standby ) then
					char_address <= "000010"; -- 02
				elsif( current_state = triggered ) then
					char_address <= "000101"; -- 05
				end if;
				
				char_col <= std_logic_vector(to_unsigned(conv_integer(vga_column) - 332,3));
			elsif( (vga_column >= 332) and (vga_column < 340) ) then -- char 7: 'D', 'Y', 'R'
				if( current_state = enabled ) then
					char_address <= "000100"; -- 04
				elsif( current_state = standby ) then
					char_address <= "011001"; -- 31
				elsif( current_state = triggered ) then
					char_address <= "010010"; -- 22
				end if;
				
				char_col <= std_logic_vector(to_unsigned(conv_integer(vga_column) - 340,3));
			elsif( (vga_column >= 340) and (vga_column < 348) ) then -- char 8: ' ', ' ', 'E'
				if( current_state = enabled ) then
					char_address <= "000000"; -- 00
				elsif( current_state = standby ) then
					char_address <= "000000"; -- 00
				elsif( current_state = triggered ) then
					char_address <= "000101"; -- 05
				end if;
				
				char_col <= std_logic_vector(to_unsigned(conv_integer(vga_column) - 348,3));
			elsif( (vga_column >= 348) and (vga_column < 356) ) then -- char 0: ' ',' ','D'
				if( current_state = enabled ) then
					char_address <= "000000"; -- 00
				elsif( current_state = standby ) then
					char_address <= "000000"; -- 00
				elsif( current_state = triggered ) then
					char_address <= "000100"; -- 04
				end if;
				
				char_col <= std_logic_vector(to_unsigned(conv_integer(vga_column) - 356,3));
			else
				char_address <= "000000";
				char_col     <= "000";
			end if;
		else
			char_address <= "000000";
			char_row <= "000";
		end if;
		
	end process;
	
	vga_color <="111" when vga_column > (mouse_cursor_column-2) and vga_column < (mouse_cursor_column+2) and vga_row >(mouse_cursor_row-2) and vga_row < (mouse_cursor_row+2)
					else vga_foreground when ((vga_row >= 20) and (vga_row < 28) and (char_address /= "000000")) and char_pixel = '1' 					
					else vga_button_one when ((vga_row < 400) and (vga_row > 320) and (vga_column>120) and (vga_column<200))
					else vga_button_two when ((vga_row < 400) and (vga_row > 320) and (vga_column>280) and (vga_column<360))
					else vga_button_three when ((vga_row < 400) and (vga_row > 320) and (vga_column>440) and (vga_column<520))
					else vga_graph_colour when ((vga_row < 32+255) and (vga_row > 32+255-distance_data) and (vga_column>270) and (vga_column<370)) -- attempt at graph implementation
					else vga_background;
					 
	out_mode <= "10" when ((mouse_cursor_row < 400) and (mouse_cursor_row > 320) and (mouse_cursor_column>120) and (mouse_cursor_column<200) and left_button='1')
			 else "01" when ((mouse_cursor_row < 400) and (mouse_cursor_row > 320) and (mouse_cursor_column>280) and (mouse_cursor_column<360) and left_button='1')
			 else "00" when ((mouse_cursor_row < 400) and (mouse_cursor_row > 320) and (mouse_cursor_column>440) and (mouse_cursor_column<520) and left_button='1')
			 else mode;
	




	
	---------------------------------------------------------------------------
	-- Read weight data (Serial)
	---------------------------------------------------------------------------
	
	-- Not used

end architecture behavior;