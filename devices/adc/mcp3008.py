import spidev
import time

class MCP3008:

	# Channel Information
	CHANNEL0 = 0b00001000
	CHANNEL1 = 0b00001001
	CHANNEL2 = 0b00001010
	CHANNEL3 = 0b00001011
	CHANNEL4 = 0b00001100
	CHANNEL5 = 0b00001101
	CHANNEL6 = 0b00001110
	CHANNEL7 = 0b00001111

	# Differentials
	DIFF_CH0_TO_CH1 = 0b00000000
	DIFF_CH1_TO_CH0 = 0b00010000
	DIFF_CH2_TO_CH3 = 0b00100000
	DIFF_CH3_TO_CH2 = 0b00110000
	DIFF_CH4_TO_CH5 = 0b01000000
	DIFF_CH5_TO_CH4 = 0b01010000
	DIFF_CH6_TO_CH7 = 0b01100000
	DIFF_CH7_TO_CH6 = 0b01110000

	def __init__( self, device, chip_select ):
		"""
		-------------------------------------------------------
		Constructs an MCP3008 ADC communication on the 
		specified chip_select
		-------------------------------------------------------
		Preconditions:
		  device  - the device to open (0 for Raspberry Pi)
		  channel - The channel to open
		-------------------------------------------------------
		"""
		self._spi = spidev.SpiDev()
		self._spi.open( device, chip_select )

	def __del__(self):
		"""
		-------------------------------------------------------
		Destructs the MCP3008, closing the SPI connection
		-------------------------------------------------------
		"""
		self._spi.close()

	def receive( self, channel, differential ):
		"""
		-------------------------------------------------------
		Receives data (10 bits) from the specified channel,
		given the expected differential
		-------------------------------------------------------
		Preconditions:
		  channel      - The MCP3008 channel to read from
		  differential - The differential to calculate
		Postconditions:
		 returns:
		  value - The value read
		-------------------------------------------------------
		"""
		response = self._spi.xfer([1, channel | differential, 0])
		# Capture 11 bits (null bit + 10 bit result)
		value = (((response[1] & 0b11) << 8) | (response[2]))

		return value
