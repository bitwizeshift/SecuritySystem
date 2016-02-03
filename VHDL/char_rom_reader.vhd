------------------------------------------------------------------------------
-- char_rom_reader
--
-- Description:
--   A reader adapter for the character rom
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

entity char_rom_reader is

	-- Inputs / Outputs -------------------------------------------------------
	port(	
		character_address	 : in	std_logic_vector(5 downto 0);
		font_row, font_col : in std_logic_vector(2 downto 0);
		clock					 : in std_logic;
		rom_mux_output		 : out std_logic
	);
			
end entity char_rom_reader;

------------------------------------------------------------------------------

architecture behavior of char_rom_reader is

	-- Signals ----------------------------------------------------------------
	signal	rom_data			: std_logic_vector(7 downto 0);
	signal	rom_address		: std_logic_vector(8 downto 0);
	
	component char_rom is
	port(
		address : in std_logic_vector (8 downto 0);
		clock	  : in std_logic  := '1';
		q		  : out std_logic_vector (7 downto 0)
	);
	end component char_rom;
	
begin

	-- small 8 by 8 character generator rom for video display
	-- each character is eight 8-bits words of pixel data
	char_gen_rom: char_rom
      port map ( address => rom_address, clock => clock, q => rom_data);

	rom_address <= character_address & font_row;

	-- mux to pick off correct rom data bit from 8-bit word
	-- for on screen character generation
	rom_mux_output <= rom_data ( (conv_integer(not font_col(2 downto 0))));

end architecture behavior;



