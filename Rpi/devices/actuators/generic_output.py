
import copy
import RPi.GPIO as GPIO


class generic_output:
	
	def __init__(self, pins):
		GPIO.setmode( GPIO.BCM )
		GPIO.setup( pins, GPIO.OUT )
		self._pins = copy.deepcopy(pins)
		return

	def __del__(self):
		GPIO.cleanup( self._pins )
		return
	
	def set(self, binary):
		for i in range(len(self._pins)):
			GPIO.output( self._pins[i], int(binary[i]) )
		return


