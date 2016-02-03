import time
import RPi.GPIO as GPIO

class Toggle:
	
	def __init__(self, pin):
		self._pin = pin
		GPIO.setmode(GPIO.BCM)
		GPIO.setup(self._pin, GPIO.OUT)
		
		self._pwm = GPIO.PWM( self._pin, 1 ) # Default frequency 1 second
		return

	def __del__(self):
		GPIO.setmode( GPIO.BCM )
		GPIO.cleanup( self._pin )
		return

	def pulse( self, t ):
		GPIO.output( self._pin, GPIO.HIGH )
		time.sleep(t)
		GPIO.output( self._pin, GPIO.LOW )
		return

	def set_high(self):
		self._pwm.stop()
		GPIO.output( self._pin, GPIO.HIGH )
		return

	def set_low(self):
		self._pwm.stop()
		GPIO.output( self._pin, GPIO.LOW )
		return

	def set(self, val):
		self.output( self._pin, val )
		return

	def toggle(self):
		self._pwm.stop()
		GPIO.output( self._pin, not GPIO.input( self._pin ) )
		return

	def enable_pwm(self, frequency, duty_cycle ):
		self._pwm.ChangeFrequency( frequency )
		self._pwm.start( duty_cycle )
		return

	def disable_pwm(self):
		self._pwm.stop()
		return

