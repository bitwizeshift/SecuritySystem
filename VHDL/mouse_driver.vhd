------------------------------------------------------------------------------
-- mouse_driver.vhd
--
-- Description:
--   The driver for the mouse, as supplied by Dr. Znotinas
--
-- Modifications:
--   Changed case of all variables to be consistent 
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
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity mouse_driver is

	-- Inputs / Outputs -------------------------------------------------------
   port( 
		clock_50mhz    : in std_logic;    -- 50mhz driving clock
		reset          : in std_logic;    -- Reset signal
	   mouse_data     : inout std_logic; -- mouse data
		mouse_clk      : inout std_logic; -- mouse driving clock
		left_button    : out std_logic;   -- left mouse button
		right_button   : out std_logic;   -- right mouse button
	   mouse_cursor_row    : out std_logic_vector(9 downto 0); -- cursor row position
	   mouse_cursor_column : out std_logic_vector(9 downto 0)  -- cursor column position
	);
	
end mouse_driver;

architecture behavior of mouse_driver is

	-- States ------------------------------------------------------------------
	type state_type is (
		inhibit_trans, 
		load_command,
		load_command2, 
		wait_output_ready, 
		wait_cmd_ack, 
		input_packets
	);

	-- Signals ----------------------------------------------------------------
	signal mouse_state        : state_type;                    -- Current mouse state
	signal inhibit_wait_count : std_logic_vector(10 downto 0); --
	signal charin,                                             -- input byte 
	       charout            : std_logic_vector(7 downto 0);  -- output byte
	signal cursor_row         : std_logic_vector(9 downto 0);  -- The cursor row location
	signal cursor_column      : std_logic_vector(9 downto 0);  -- The cursor column location
	signal new_cursor_row     : std_logic_vector(9 downto 0);  -- New cursor row position
	signal new_cursor_column  : std_logic_vector(9 downto 0);  -- New cursor column position
	signal incnt              : std_logic_vector(3 downto 0);  -- Input count
	signal outcnt             : std_logic_vector(3 downto 0);  -- Output count
	signal msb_out            : std_logic_vector(3 downto 0);  -- Most Signifcant Bit (MSB) out
	signal packet_count       : std_logic_vector(1 downto 0);  -- Current location in the packet
	signal shiftin            : std_logic_vector(8 downto 0);  -- value being shifted in
	signal shiftout           : std_logic_vector(10 downto 0); -- Value being shifted out
	signal packet_char1,                                       -- Packet Byte 1
	       packet_char2,                                       -- Packet Byte 2
	       packet_char3       : std_logic_vector(7 downto 0);  -- Packet Byte 3
	signal mouse_clk_buf, 
	       data_ready, 
			 read_char	        : std_logic;
	signal cursor, 
	       iready_set, 
			 break, 
			 toggle_next,
			 output_ready, 
			 send_char, 
			 send_data 	        : std_logic;
	signal mouse_data_dir, 
	       mouse_data_out, 
	       mouse_data_buf     : std_logic;
	signal mouse_clk_dir, 
	       mouse_clk_filter   : std_logic;
	signal clock_25mhz        : std_logic;                     -- 25 mhz 'logical' clock
	signal clock_12mhz        : std_logic;                     -- 12.5 mhz 'logical' clock, made from 25 mhz clock
	signal filter             : std_logic_vector(7 downto 0);  --
	signal mouse_clk_rising_edge  : std_logic;                 -- Mouse clock rising edge value
	signal mouse_clk_falling_edge : std_logic;                 -- Mouse clock falling edge value

begin

	-- Output cursor row and column
	mouse_cursor_row    <= cursor_row;
	mouse_cursor_column <= cursor_column;

	-- tri_state control logic for mouse data and clock lines
	mouse_data <= 'Z' when mouse_data_dir = '0' else mouse_data_buf;
	mouse_clk  <= 'Z' when mouse_clk_dir = '0' else mouse_clk_buf;

	-- generate slower clock for mouse state machine
	process 
	begin
		wait until clock_50mhz'event and clock_50mhz = '1';
		clock_25mhz <= not clock_25mhz;
	end process;

	-- Generate even slower clock for mouse state machine
	process
	begin
		wait until clock_25mhz'event and clock_25mhz = '1';
		clock_12mhz <= not clock_12mhz;
	end process;
	
	---------------------------------------------------------------------------

	-- state machine to send init command and start recv process.
	process (reset, clock_12mhz)
	begin
		if reset = '0' then
			mouse_state <= inhibit_trans;
			inhibit_wait_count <= conv_std_logic_vector(0,11);
			send_data <= '0';
		elsif clock_12mhz'event and clock_12mhz = '1' then
			case mouse_state is

	-- mouse powers up and sends self test codes, aa and 00 out before board is downloaded
	-- pull clock line low to inhibit any transmissions from mouse
	-- need at least 60usec to stop a transmission in progress
	-- note: this is perhaps optional since mouse should not be transmitting
				when inhibit_trans =>
					inhibit_wait_count <= inhibit_wait_count + 1;
					if inhibit_wait_count(10 downto 9) = "11" then
						mouse_state <= load_command;
					end if;
					-- enable streaming mode command, f4
					charout <= "11110100";
					-- pull data low to signal data available to mouse

				when load_command =>
					send_data <= '1';
					mouse_state <= load_command2;

				when load_command2 =>
					send_data <= '1';
					mouse_state <= wait_output_ready;

	-- wait for mouse to clock out all bits in command.
	-- command sent is f4, enable streaming mode
	-- this tells the mouse to start sending 3-byte packets with movement data
				when wait_output_ready =>
					send_data <= '0';
	-- output ready signals that all data is clocked out of shift register
					if output_ready='1' then
						mouse_state <= wait_cmd_ack;
					else
						mouse_state <= wait_output_ready;
					end if;

	-- wait for mouse to send back command acknowledge, fa
				when wait_cmd_ack =>
					send_data <= '0';
					if iready_set='1' then
						mouse_state <= input_packets;
					end if;

	-- release clock_12mhz and data lines and go into mouse input mode
	-- stay in this state and receive 3-byte mouse data packets forever
	-- default rate is 100 packets per second
				when input_packets =>
					mouse_state <= input_packets;
			end case;
		end if;
	end process;

	with mouse_state select
	-- mouse data tri-state control line: '1' fpga drives, '0'=mouse drives
		mouse_data_dir 	<=	'0'	when inhibit_trans,
						'0'	when load_command,
						'0'	when load_command2,
						'1'	when wait_output_ready,
						'0'	when wait_cmd_ack,
						'0'	when input_packets;

	with mouse_state select
	-- mouse clock tri-state control line: '1' fpga drives, '0'=mouse drives
		mouse_clk_dir 	<=	'1'	when inhibit_trans,
						'1'	when load_command,
						'1'	when load_command2,
						'0'	when wait_output_ready,
						'0'	when wait_cmd_ack,
						'0'	when input_packets;

	with mouse_state select
	-- input to fpga tri-state buffer mouse clock_12mhz line
		mouse_clk_buf 	<=	'0'	when inhibit_trans,
						'1'	when load_command,
						'1'	when load_command2,
						'1'	when wait_output_ready,
						'1'	when wait_cmd_ack,
						'1'	when input_packets;

	-- filter for mouse clock
	process
	begin
		wait until clock_12mhz'event and clock_12mhz = '1';
			filter(7 downto 1) <= filter(6 downto 0);
			filter(0) <= mouse_clk;
			if filter = "11111111" then
	------------------  start of modification  -----------------
				if (mouse_clk_filter='0') then		
					mouse_clk_rising_edge <= '1';
				else
					mouse_clk_rising_edge <= '0';
				end if;
	------------------  end of modification  -------------------
				mouse_clk_filter <= '1';
			elsif filter = "00000000" then
	------------------  start of modification  -----------------
				if (mouse_clk_filter='1') then		
					mouse_clk_falling_edge <= '1';
				else
					mouse_clk_falling_edge <= '0';
				end if;
	------------------  end of modification  -------------------
				mouse_clk_filter <= '0';
			end if;
	end process;

	--this process sends serial data going to the mouse
	send_uart: process (send_data, clock_12mhz, charout)
	begin

	if send_data = '1' then
		outcnt <= "0000";
		send_char <= '1';
		output_ready <= '0';
		-- send out start bit(0) + command(f4) + parity  bit(0) + stop bit(1)
		shiftout(8 downto 1) <= charout ;
		-- start bit
		shiftout(0) <= '0';
		-- compute odd parity bit
		shiftout(9) <=  not (charout(7) xor charout(6) xor charout(5) 
			xor charout(4) xor charout(3) xor charout(2) xor charout(1) 
			xor charout(0));
		-- stop bit 
		shiftout(10) <= '1';
		-- data available flag to mouse
		-- tells mouse to clock out command data (is also start bit)
		mouse_data_buf <= '0';

	elsif(clock_12mhz'event and clock_12mhz='1') then
		if mouse_clk_falling_edge='1' then
			if mouse_data_dir='1' then
			-- shift out next serial bit
				if send_char = '1' then
			-- loop through all bits in shift register
						if outcnt <= "1001" then
							outcnt <= outcnt + 1;
			-- shift out next bit to mouse
							shiftout(9 downto 0) <= shiftout(10 downto 1);
						shiftout(10) <= '1';
								mouse_data_buf <= shiftout(1);
						output_ready <= '0';
			-- end of character
					else
							send_char <= '0';
			-- signal the character has been output
						output_ready <= '1';
						outcnt <= "0000";
					end if;
				end if;
			end if;
		end if;
	end if;
	end process send_uart;


	recv_uart: process(reset, clock_12mhz)
	begin

	if reset='0' then
		incnt <= "0000";
		read_char <= '0';
		packet_count <= "00";
		left_button <= '0';
		right_button <= '0';
		charin <= "00000000";

	elsif (clock_12mhz'event and clock_12mhz='1') then
		if mouse_clk_rising_edge='1' then
			if mouse_data_dir='0' then
				if mouse_data='0' and read_char='0' then
					read_char<= '1';
						iready_set<= '0';
				else
		-- shift in next serial bit
					if read_char = '1' then
						  if incnt < "1001" then
								incnt <= incnt + 1;
								shiftin(7 downto 0) <= shiftin(8 downto 1);
								shiftin(8) <= mouse_data;
						iready_set <= '0';
		-- end of character
					  else
						charin <= shiftin(7 downto 0);
							read_char <= '0';
						iready_set <= '1';
						packet_count <= packet_count + 1;


		-- packet_count = "00" is ack command
						  if packet_count = "00" then
		-- set cursor to middle of screen
							  cursor_column <= conv_std_logic_vector(320,10);
								  cursor_row <= conv_std_logic_vector(240,10);
							  new_cursor_column<=conv_std_logic_vector(320,10);
								  new_cursor_row <= conv_std_logic_vector(240,10);


						  elsif packet_count = "01" then
							packet_char1 <= shiftin(7 downto 0);

		-- limit cursor on screen edges	

		-- check for left screen limit
		-- all numbers are positive only, and need to check for zero wrap around.
		-- set limits higher since mouse can move up to 128 pixels in one packet
							if (cursor_row<128) and ((new_cursor_row>256) or 
							  (new_cursor_row < 2)) then
								cursor_row <= conv_std_logic_vector(0,10);

		-- check for right screen limit
							elsif new_cursor_row > 480 then
								cursor_row<=conv_std_logic_vector(480,10);
							else
								cursor_row <= new_cursor_row;
							end if;

		-- check for top screen limit
							if (cursor_column < 128) and 
							  ((new_cursor_column > 256) or
							  (new_cursor_column < 2)) then
								 cursor_column<=conv_std_logic_vector(0,10);

		-- check for bottom screen limit
							elsif new_cursor_column > 640 then
							 cursor_column <= conv_std_logic_vector(640,10);
							else
								cursor_column <= new_cursor_column;
							end if;


						elsif packet_count = "10" then
							packet_char2 <= shiftin(7 downto 0);


						elsif packet_count = "11" then
							packet_char3 <= shiftin(7 downto 0);
						end if;
						incnt <= conv_std_logic_vector(0,4);


						if packet_count = "11" then
								packet_count <= "01";
		-- packet complete, so process data in packet
		-- sign extend x and y two's complement motion values and 
		-- add to current cursor address
		--
		-- y motion is negative since up is a lower row address
								new_cursor_row <= cursor_row - (packet_char3(7)&packet_char3(7)&packet_char3);
								new_cursor_column <= cursor_column + (packet_char2(7)&packet_char2(7)&packet_char2);
								left_button <= packet_char1(0);
								right_button <= packet_char1(1);
						end if;
						end if;
					end if;
				end if;
			end if;
		end if;
	end if;
	end process recv_uart;

end behavior;


library ieee;
use  ieee.std_logic_1164.all;
use  ieee.std_logic_arith.all;
use  ieee.std_logic_unsigned.all;

package mouse_driver_pkg is
		component mouse_driver is
		port( clock_50mhz, reset 			: in std_logic;
			signal mouse_data			: inout std_logic;
         signal mouse_clk 			: inout std_logic;
         signal left_button	: out std_logic;
		   signal right_button	: out std_logic;
			signal mouse_cursor_row 		: out std_logic_vector(9 downto 0); 
			signal mouse_cursor_column 	: out std_logic_vector(9 downto 0));
	end component mouse_driver;	
end package mouse_driver_pkg;
