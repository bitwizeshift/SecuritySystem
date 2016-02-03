-------------------------------------------------------------------------------
-- Names : Matthew Rodusek (rodu4140@mylaurier.ca)
-- ID    : 120184140
-- Date  : 2015-10-27
--
-- Purpose: Generic designed BCD converter, taking a user specified number of 
--          bits on input, and converting to n specified nibbles of output
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
-------------------------------------------------------------------------------
entity bin_to_bcd is
	generic( input_bits     : integer := 4;  -- Number of bits for input (also max possible shifts)
	         output_nibbles : integer := 2); -- Output nibbles (4 bit pairs)
	port( in_bits  : in  std_logic_vector((input_bits - 1) downto 0);
			out_bits : out std_logic_vector((output_nibbles * 4) - 1 downto 0) );
end entity bin_to_bcd;
-------------------------------------------------------------------------------
architecture structure of bin_to_bcd is
	-- Make all columns exist in a single vector for easy shifting, using aliases to differentiate the different parts
begin
	conv_bcd: process( in_bits ) 
		variable all_columns : std_logic_vector( (in_bits'length + out_bits'length - 1) downto 0 );
		alias    bits        : std_logic_vector( in_bits'range )  is all_columns( in_bits'range );
		alias    columns     : std_logic_Vector( out_bits'range ) is all_columns( all_columns'left downto (in_bits'length) );
	begin
		bits    := in_bits;          -- Start with assigned bits
		columns := (others => '0');  -- Assume all columns are 0
		
		-- Loop until all bits are shifted
		for shift in 1 to input_bits loop
			
			-- Check if any columns exceed value 4
			for i in 0 to (output_nibbles-1) loop
				if( columns( (4*(i+1)-1) downto (4*i) ) >= 5 ) then
				                                       -- std_logic_vector(unsigned(columns( (4*(i+1)-1) downto (4*i) )) + 3); -- Add 3 to the value
					columns( (4*(i+1)-1) downto (4*i) ) := columns( (4*(i+1)-1) downto (4*i) ) + 3; -- Add 3 to the value
				end if;
			end loop; -- for loop 
		
			-- perform left shift
			all_columns := all_columns((all_columns'left-1) downto 0) & '0';
			
		end loop; -- for loop
		
		-- Finally assign the final converted value
		out_bits <= columns;
	end process conv_bcd;
end architecture structure;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
package bcd_pkg is

	component bin_to_bcd is
		generic( input_bits  : integer := 4;  -- Number of bits for input (also max possible shifts)
	         output_nibbles : integer := 2); -- Output nibbles (4 bit pairs)
		port( in_bits  : in  std_logic_vector((input_bits - 1) downto 0);
				out_bits : out std_logic_vector((output_nibbles * 4) - 1 downto 0) );
	end component bin_to_bcd;
	
end package bcd_pkg;