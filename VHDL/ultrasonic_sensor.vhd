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

entity ultrasonic_sensor is

	-- Generics ---------------------------------------------------------------
	generic(
		frequency : natural := 5000000; -- Clock frequency (hz)
		max_cm    : natural := 10;      -- Max distance (in cm)
		out_bits  : natural := 8        -- Number of output bits
	);

	-- Inputs / Outputs -------------------------------------------------------
	port(
		reset   : in std_logic; -- Reset for state machine
		clk     : in std_logic; -- Clock for state machine
		trigger : in std_logic; -- Trigger signal 
		echo    : in std_logic; -- 
		dataout : out std_logic_vector( out_bits-1 downto 0 ) := (others => '0')
	);
	
end entity ultrasonic_sensor;

------------------------------------------------------------------------------

architecture behavior of ultrasonic_sensor is

	-- Constants --------------------------------------------------------------
	constant speed_of_sound_cmps : natural := 34029; 
	constant ticks_per_cm        : natural := (frequency / speed_of_sound_cmps);
	constant max_ticks           : natural := ticks_per_cm * max_cm * 2;
	constant max_dataout         : std_logic_vector( out_bits-1 downto 0 ) := (others => '1');
	constant max_value           : natural := to_integer(unsigned(max_dataout));

	-- Enumerations -----------------------------------------------------------
	type state_type is (
		wait_for_trigger,     -- Wait for the trigger signal to send
		wait_for_echo_rising, -- Wait for the rising-edge of echo
		wait_for_echo_falling -- Wait for the falling-edge of echo
	);
	
	-- Signals ----------------------------------------------------------------
	signal tick_count : natural    := 0;
	signal state      : state_type := wait_for_trigger;
begin
	-- state machine to handle echo
	process( clk, reset )
	begin
	
		if reset = '0' then
			state      <= wait_for_trigger;
			tick_count <= 0;
		else
			if (clk'event and clk = '1') then
				case state is
					-- Wait for the trigger ----------------------------------------
					when wait_for_trigger =>
						if trigger = '1' then
							state      <= wait_for_echo_rising;
							tick_count <= 0; -- reset tick count
						else
							state      <= wait_for_trigger;
							tick_count <= 0;
						end if;
					-- Wait for the echo's rising edge -----------------------------
					when wait_for_echo_rising =>
						if echo = '1' then 
							state      <= wait_for_echo_falling;
							tick_count <= 1; -- Count the first tick
						else 
							state      <= wait_for_echo_rising;
							tick_count <= 0;
						end if;
					-- Wait for the echo's falling edge ----------------------------
					when wait_for_echo_falling =>
						if echo = '1' then
							tick_count <= tick_count + 1;	-- Count the number of ticks
							state      <= wait_for_echo_falling;
						else
							state      <= wait_for_trigger; -- Wait for next trigger
							if tick_count >= max_ticks then
								dataout <= max_dataout;
							else
								dataout <= std_logic_vector( to_unsigned( ((tick_count * max_value) / max_ticks), out_bits) );
							end if;
							tick_count <= 0;
						end if;
					----------------------------------------------------------------
				end case;
			end if;
		end if;
	end process;
	
end architecture behavior;