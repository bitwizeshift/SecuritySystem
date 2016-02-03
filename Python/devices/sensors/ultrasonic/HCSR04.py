import RPi.GPIO as GPIO
import time

"""
------------------------------------------------------------------------------
Useful constants
------------------------------------------------------------------------------
"""

MICROSEC_TO_HZ           = 1000000.0              # 1/s
MICROSEC_TO_SEC          = 1.0/1000000.0          # s

class HCSR04:
	"""
	--------------------------------------------------------------------------
	HC-SR04 Ultrasonic Sensor
	--------------------------------------------------------------------------
	Description:
	  The HC-SR04 is an ultrasonic sensor for up to 400cm. 
	  It triggers from a rising edge pulse of at least 20 microseconds, and 
	  the delay to the echoed falling edge is proportional to the distance of 
	  the closest object.
	--------------------------------------------------------------------------
	"""

	# Class constants
	MIN_TRIGGER_TIME = 20.0 # uS

	def __init__( self, trigger, echo, callback ):
		"""
		----------------------------------------------------------------------
		Initializes the ultrasonic sensor when provided the pins for the 
		trigger and echo, along with the function to call when a result is
		retrieved
		----------------------------------------------------------------------
		Preconditions:
		  trigger  - the pin to trigger the ultrasonic sensor
		  echo     - the pin to receive data from the ultrasonic sensor
		  callback - The function to call once echo has returned. (function with param for distance)
		----------------------------------------------------------------------
		"""
		def echo_callback( channel ):
			"""
			------------------------------------------------------------------
			Internal function for threaded callback. This is called on the
			rising edge of echo, simply to record the start time it was sent
			------------------------------------------------------------------
			"""
			if GPIO.input(channel) and not self._triggered:
				self._start = time.time()
				self._triggered = True
				print("start")
			elif self._triggered:
				self._stop = time.time()
				self._triggered = False
				print("stop")
				callback( self._stop - self._start )
			return
						
		default_frequency = HCSR04.MIN_TRIGGER_TIME * MICROSEC_TO_HZ
		self._trigger_pin = trigger
		self._echo_pin    = echo
		self._stop        = 0
		self._start       = 0
		self._triggered   = False

		GPIO.setmode( GPIO.BCM )
		
		GPIO.setup( self._trigger_pin, GPIO.OUT )
		GPIO.setup( self._echo_pin,    GPIO.IN )

		self._pwm = GPIO.PWM( self._trigger_pin, default_frequency )		
		
		# Time the start and end of the echo to calculate distance
		GPIO.add_event_detect( self._echo_pin, GPIO.BOTH )
		GPIO.add_event_callback( self._echo_pin, echo_callback  )
		
	def __del__(self):
		"""
		----------------------------------------------------------------------
		Destructs this ultrasonic sensor, closing any open GPIO pins
		----------------------------------------------------------------------
		"""
		GPIO.setmode( GPIO.BCM )
		self._pwm.stop()
		print("testing")
		
		GPIO.cleanup( self._echo_pin )
		GPIO.cleanup( self._trigger_pin )
		return
					
	def enable( self, frequency, duty_cycle = 50.0 ):
		"""
		----------------------------------------------------------------------
		Enables the ultrasonic sensor using pulse-width modulation.
		----------------------------------------------------------------------
		Preconditions:
		  frequency  - the frequency of the trigger pulses
		  duty_cycle - the duty cycle (in percent) of the waveform (default: 50.0)
		Postconditions:
		  PWM is enabled
		----------------------------------------------------------------------
		"""
		if duty_cycle < 0.0:
			duty_cycle = 0.0
		elif duty_cycle > 100.0:
			duty_cycle = 100.0

						
		self._pwm.ChangeFrequency( frequency )
		self._pwm.start( duty_cycle )
		
		return
		
	def disable( self ):
		"""
		----------------------------------------------------------------------
		Disables the ultrasonic sensor's PWM, if enabled
		----------------------------------------------------------------------
		Postconditions:
		  PWM is disabled
		----------------------------------------------------------------------
		"""
		self._pwm.stop()
		print("Disabled")
		return
			
	def trigger( self, microseconds = 0 ):
		"""
		----------------------------------------------------------------------
		Triggers the ultrasonic sensor with the specified length of pulse
		----------------------------------------------------------------------
		Preconditions:
		  microseconds - the number of microseconds to send the pulse
		Postconditions:
		  ultrasonic sensor is triggered; releases 8 40khz pulses
		----------------------------------------------------------------------
		"""
		self._pwm.stop()
		if microseconds < HCSR04.MIN_TRIGGER_TIME:
			microseconds = HCSR04.MIN_TRIGGER_TIME
			
		seconds = microseconds * MICROSEC_TO_SEC
		
		GPIO.output( self._trigger_pin, GPIO.HIGH )
		time.sleep( seconds )
		GPIO.output( self._trigger_pin, GPIO.LOW )
						
