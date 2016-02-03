import RPi.GPIO as GPIO

class Switch:

	def __init__(self, pin):

		def value_callback( channel ):
			if GPIO.input(channel):
				if self._on_rising:
					self._on_rising()
			else:
				if self._on_falling:
					self._on_falling()
			return

		self._on_rising  = None
		self._on_falling = None
		self._pin = pin
		GPIO.setmode(GPIO.BCM)
		GPIO.setup( self._pin, GPIO.IN )

		# Call function on change, passing value
		GPIO.add_event_detect( self._pin, GPIO.BOTH )
		GPIO.add_event_callback( self._pin, value_callback )
		return

	def set_on_rising(self, function):
		self._on_rising = function
		return
	
	def set_on_falling(self, function):
		self._on_falling = function
		return
	

	def __del__( self ):
		GPIO.cleanup( self._pin )
		return	
