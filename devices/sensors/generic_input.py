import copy
import RPi.GPIO as GPIO


class generic_input:
	
	def __init__(self, pins):
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
		GPIO.setmode( GPIO.BCM )
		GPIO.setup( pins, GPIO.IN )
		self._pins = copy.deepcopy(pins)
		for pin in self._pins:
			GPIO.add_event_detect( pin, GPIO.BOTH )
			GPIO.add_event_callback( pin, value_callback )
		return

	def __del__(self):
		GPIO.cleanup( self._pins )
		return
	
	def get(self):
		result = ""
		for pin in self._pins:
			result += str( GPIO.input( pin ))
		return result

	def set_on_rising(self, function):
		self._on_rising = function
		return
	
	def set_on_falling(self, function):
		self._on_falling = function
		return
	

