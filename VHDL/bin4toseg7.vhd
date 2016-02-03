-------------------------------------------------------------------------------
-- Names : Matthew Rodusek (rodu4140@mylaurier.ca)
-- ID    : 120184140
-- Date  : 2015-11-01
--
-- Purpose: Converts 4 bit inputs into 7-segment display output.
--          Note that this only works for hex integers between 0 and E, 
--          otherwise the output is empty
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
-------------------------------------------------------------------------------
entity bin4toseg7 is
	port( input  : in std_logic_vector(3 downto 0);     -- 4 bits input
			output : out std_logic_vector(6 downto 0));   -- 7 bits output (for 7 segments)
end entity bin4toseg7;
-------------------------------------------------------------------------------
architecture structure of bin4toseg7 is
begin

	with conv_integer(input) select 
		output <=
			"1000000" when 0,
			"1111001" when 1,
			"0100100" when 2,
			"0110000" when 3,
			"0011001" when 4,
			"0010010" when 5,
			"0000010" when 6,
			"1111000" when 7,
			"0000000" when 8,
			"0010000" when 9,
			"0001000" when 10,
			"0000011" when 11,
			"1000110" when 12,
			"0100001" when 13,
			"0000110" when 14,
			"0001110" when 15,
			"0000000" when others; 
end architecture structure;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
package seg7_pkg is

	component bin4toseg7 is
	port( input  : in std_logic_vector(3 downto 0);     -- 4 bits input
			output : out std_logic_vector(6 downto 0));   -- 7 bits output (for 7 segments)
	end component bin4toseg7;
	
end package seg7_pkg;