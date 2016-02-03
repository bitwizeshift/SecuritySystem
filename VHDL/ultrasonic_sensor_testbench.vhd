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

entity ultrasonic_sensor_testbench is
end entity ultrasonic_sensor_testbench;

------------------------------------------------------------------------------

architecture behavior of ultrasonic_sensor_testbench is

	-- Signals ----------------------------------------------------------------
	signal clk     : std_logic := '0';
	signal reset   : std_logic := '0';
	signal trigger : std_logic := '0';
	signal echo    : std_logic := '0';
	signal dataout : std_logic_vector(7 downto 0);
	--signal dataout : natural;
	signal is_running : boolean := true;
	
	component ultrasonic_sensor is

		generic(
			frequency : natural := 5000000; -- Clock frequency (hz)
			max_cm    : natural := 10;      -- Max distance (in cm)
			out_bits  : natural := 8        -- Number of output bits
		);

		port(
			reset   : in std_logic; -- Reset for state machine
			clk     : in std_logic; -- Clock for state machine
			trigger : in std_logic; -- Trigger signal 
			echo    : in std_logic; -- 
			dataout : out std_logic_vector( out_bits-1 downto 0 ) := (others => '0')
			--dataout : out natural
		);
	
	end component ultrasonic_sensor;
begin

	ultra_label: 
		ultrasonic_sensor 
		port map( 
			reset       => reset, 
			clk         => clk, 
			trigger     => trigger, 
			echo        => echo, 
			dataout     => dataout
		);
	
	clk <= not clk after 10 ns when is_running else '0';
	reset <= '0';

	process
	begin
	
		trigger <= '1'; wait for 100 ns;
		trigger <= '0'; wait for 20 ns;
		echo <= '1'; wait for 100 ns;
		echo <= '0'; wait for 20 ns;
		
		trigger <= '1'; wait for 100 ns;
		trigger <= '0'; wait for 20 ns;
		echo <= '1'; wait for 1000 ns;
		echo <= '0'; wait for 20 ns;
		
		--
		trigger <= '1'; wait for 100 ns;
		trigger <= '0'; wait for 20 ns;
		echo <= '1'; wait for 2920 ns; -- Should be ~25
		echo <= '0'; wait for 20 ns;
		
		is_running <= false;
		wait;
	end process;

end architecture behavior;