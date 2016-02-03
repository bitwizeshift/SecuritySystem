------------------------------------------------------------------------------
-- vga_sync
--
-- Description:
--   A small, modular entity capable of generating synchronization signals 
--   compliant with the 640x480@60hz VGA-standard. 
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

entity vga_sync is
	
	-- Inputs / Outputs -------------------------------------------------------
	port(
		clock         : in  std_logic; -- Clock signal in
		h_sync        : out std_logic; -- Horizontal synchronization signal
		v_sync        : out std_logic; -- Vertical synchronization signal
		video_enabled : out std_logic; -- Is video currently enabled?
		pixel_row     : out std_logic_vector(9 downto 0); -- Output pixel row
		pixel_column  : out std_logic_vector(9 downto 0)  -- Output pixel column
	);
	
end entity vga_sync;

------------------------------------------------------------------------------

architecture behavior of vga_sync is
	
	-- Signals ----------------------------------------------------------------
	signal h_count, v_count : std_logic_vector(9 downto 0); -- Horizontal and vertical count
	
begin

	-- Generate sync signals and pixel locations
	sync_timing: process --( clock )
	begin		
		wait until(clock'event) AND (clock = '1');
		
			----------------------------------------------------------------------
			-- Horizontal Sync
			----------------------------------------------------------------------

			-- H_count counts pixels (640 + extra time for sync signals)
			--  Horiz_sync  ------------------------------------__________--------
			--  H_count       0                640             659       755    799
			--
			
			if (h_count = 799) then
				h_count <= (others => '0');
			else
				h_count <= h_count + 1;
			end if;
			
			if ((h_count <= 755) and (h_count >= 659)) then
				h_sync <= '0';
			else
				h_sync <= '1';
			end if;

			----------------------------------------------------------------------
			-- Vertical Sync
			----------------------------------------------------------------------

			-- V_count counts rows of pixels (480 + extra time for sync signals)
			--  Vert_sync  ----------------------------------_______------------
			--  V_count     0                         480    493-494          524
			--
			
			if ((v_count >= 524) and (h_count >= 699)) then
				v_count <= (others => '0');
			elsif (h_count = 699) then
				v_count <= v_count + 1;
			end if;
			
			if ((v_count <= 494) and (v_count >= 493)) then
				v_sync <= '0';
			else
				v_sync <= '1';
			end if;
						
			------------------------------------------------------------------------
			-- Pixel row/column for output
			------------------------------------------------------------------------
			
			if ( h_count < 640 ) then
				pixel_column <= h_count;
			end if;
			if ( v_count < 480 ) then
				pixel_row <= v_count;
			end if;
			
			------------------------------------------------------------------------
			-- Detect if display is enabled
			------------------------------------------------------------------------
			
			-- Check if in front porch, sync, or back porch region
			if (h_count < 640) and (v_count < 480) then
				video_enabled <= '1';
			else
				video_enabled <= '0';
			end if;

			
--		end if;
	end process sync_timing;
end architecture behavior;

------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

package sync_pkg is

	component vga_sync is
		port(
			clock         : in  std_logic; -- Clock signal in
			h_sync        : out std_logic; -- Horizontal synchronization signal
			v_sync        : out std_logic; -- Vertical synchronization signal
			video_enabled : out std_logic; -- Is video currently enabled?
			pixel_row     : out std_logic_vector(9 downto 0); -- Output pixel row
			pixel_column  : out std_logic_vector(9 downto 0)  -- Output pixel column
		);
	end component vga_sync;
	
end package sync_pkg;