import spidev

class CPA417:

	# Shutdown Constants
	SHUTDOWN_A   = 0x20
	SHUTDOWN_B   = 0x30
	SHUTDOWN_ALL = SHUTDOWN_A | SHUTDOWN_B

	# Load Constants
	LOAD_A       = 0x01
	LOAD_B       = 0x02
	LOAD_BOTH    = LOAD_A | LOAD_B

	def __init__(self, device, chip_select ):
		"""
		------------------------------------------------------------------------		
		Constructs a CPA417 object on the given device from the channel select
		------------------------------------------------------------------------
		Preconditions:
		  device      - the device to read
		  chip_select - the chip selection pin to use		
		------------------------------------------------------------------------		
		"""
		self._spi = spidev.SpiDev()
		self._spi.open( device, chip_select )
		return

	def __del__(self):
		"""
		------------------------------------------------------------------------		
		Destructs the CPA417 by calling to shutdown all dac registers, then
		closing the SPI connection
		------------------------------------------------------------------------				
		"""
		self._spi.xfer2([ (SHUTDOWN_ALL) , 0])
		self._spi.close()
		return

	def send(self, operation, value):
		"""
		------------------------------------------------------------------------
		Sends a value using the specified operation. Note that values outside
		of the range [0..255] will be clamped
		------------------------------------------------------------------------
		Preconditions:
		  operation - The operation to perform (constant)
		  value     - The value to send to the DAC [0..255]		
		Postconditions:
		  DAC receives 8 bit data, converting it to analog
		------------------------------------------------------------------------
		"""
		# Manually clamp imput
		if value < 0:
			value = 0
		elif value > 255:
			value = 255
		
		self._spi.xfer2([ operation, value ])
		return
	
