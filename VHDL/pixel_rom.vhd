------------------------------------------------------------------------------
-- pixel_rom
--
-- Description:
--   Small architecture to convert 3-bit image data into solid colors on the
--   VGA driver. Not entirely sure this class is even necessary
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

entity pixel_rom is

	-- Generic information for the VGA sync -----------------------------------
	generic( 
		color_size : integer := 10
	); 

	-- Inputs / Outputs -------------------------------------------------------
	port(
		image_data  : in std_logic_vector(2 downto 0);
		r_color, g_color, b_color : out std_logic_vector( color_size-1 downto 0 )
	);
		
end entity pixel_rom;
------------------------------------------------------------------------------
architecture behavior of pixel_rom is
begin
	
	r_color <= (others => '1') when (image_data(2) = '1') else (others=>'0');
	g_color <= (others => '1') when (image_data(1) = '1') else (others=>'0');
	b_color <= (others => '1') when (image_data(0) = '1') else (others=>'0');
	
end architecture behavior;		

------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

package pixel_rom_pkg is
	component pixel_rom is

		-- Generic information for the VGA sync --------------------------------
		generic( 
			color_size : integer := 10
		); 

		-- Inputs / Outputs ----------------------------------------------------
		port(
			image_data  : in std_logic_vector(2 downto 0);
			r_color, g_color, b_color : out std_logic_vector( color_size-1 downto 0 )
		);
		
	end component pixel_rom;
	
end package pixel_rom_pkg;