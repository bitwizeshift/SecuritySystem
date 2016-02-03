# Time
import time

# Audio Handling
import wave
import ossaudiodev as oss

# Devices
from devices.actuators.Toggle import Toggle
from devices.sensors.switches.Switch import Switch
from devices.adc.mcp3008 import MCP3008

1from devices.sensors.generic_input import generic_input
from devices.actuators.generic_output import generic_output

import devices.pi as pi
import pygame

# GPIO
import RPi.GPIO as GPIO

# System
from subprocess import call

# Set sound to come out of speaker
call( ["amixer", "cset", "numid=3", "1"] )

#---------------------------------------------------------------------
# Pin Constants (In Broadcom)
#---------------------------------------------------------------------

PIN_LED_RED     = 13
PIN_LED_GREEN   = 26
PIN_LED_YELLOW  = 19
PIN_BEEPER      = 12
PIN_HCSR04_TRIG = 21
PIN_HCSR04_ECHO = 25

PIN_RADIO_SWITCH_A = 20
PIN_RADIO_SWITCH_B = 16

PIN_IN_MODE_1 = 27   # Used to detect mode changes from DE board
PIN_IN_MODE_2 = 22   # "

PIN_OUT_MODE_1 = 23  # Used to send mode changes to DE board
PIN_OUT_MODE_2 = 24  # "

ADC_DEVICE      = pi.DEVICE
ADC_CHIP_SELECT = pi.CHIP_SELECT_1

#---------------------------------------------------------------------
# State Constants
#---------------------------------------------------------------------

STATE_STANDBY   = 0
STATE_ENABLED   = 1
STATE_TRIGGERED = 2

STATE_STANDBY_STR   = "00"
STATE_ENABLED_STR   = "01"
STATE_TRIGGERED_STR = "10"

ULTRASONIC_THRESHOLD = 0.95e-4 # Threshold for detection
PRESSURE_THRESHOLD   = 8       # Threshold for force detection

ULTRASONIC_QUEUE_SIZE = 4
PRESSURE_QUEUE_SIZE   = 3

SLEEP_TIME = 0.1 # 0.1

#---------------------------------------------------------------------
# Toggle assignment
#---------------------------------------------------------------------

red_led    = Toggle( PIN_LED_RED    )
yellow_led = Toggle( PIN_LED_YELLOW )
green_led  = Toggle( PIN_LED_GREEN  )
beeper     = Toggle( PIN_BEEPER     )
adc        = MCP3008( ADC_DEVICE, ADC_CHIP_SELECT )

red_led.set_low()
yellow_led.set_low()
green_led.set_high()

beeper.set_low()

radio_a = Switch( PIN_RADIO_SWITCH_A )
radio_b = Switch( PIN_RADIO_SWITCH_B )

#state_in  = generic_input([  PIN_IN_MODE_1,  PIN_IN_MODE_2  ])
state_in  = [ PIN_IN_MODE_1, PIN_IN_MODE_2 ]
state_out = [ PIN_OUT_MODE_1, PIN_OUT_MODE_2 ] 
#state_out = generic_output([ PIN_OUT_MODE_1, PIN_OUT_MODE_2 ])

GPIO.setup( state_in,  GPIO.IN  )
GPIO.setup( state_out, GPIO.OUT )

trigger = Toggle( PIN_HCSR04_TRIG )

GPIO.setup( PIN_HCSR04_ECHO, GPIO.IN )

current_state     = STATE_STANDBY
current_state_str = STATE_STANDBY_STR


#state_in  = generic_input([  PIN_IN_MODE_1,  PIN_IN_MODE_2  ])
state_in  = [ PIN_IN_MODE_1, PIN_IN_MODE_2 ]
state_out = [ PIN_OUT_MODE_1, PIN_OUT_MODE_2 ]
#state_out = generic_output([ PIN_OUT_MODE_1, PIN_OUT_MODE_2 ])

GPIO.setup( state_in,  GPIO.IN  )
GPIO.setup( state_out, GPIO.OUT )

GPIO.output( state_out[0], int(STATE_STANDBY_STR[0]) )
GPIO.output( state_out[1], int(STATE_STANDBY_STR[1]) )


pygame.mixer.init() # Initialize python sounds

alarm   = pygame.mixer.Sound("alarm.wav")
working = pygame.mixer.Sound("working.wav")


#---------------------------------------------------------------------
# State Changes
#---------------------------------------------------------------------

def notify_de_board( state ):
	global state_out
	global state_in

	#GPIO.output( state_out[0], int(state[0]) )
	#GPIO.output( state_out[1], int(state[1]) )

	GPIO.output( (state_out[0], state_out[1]), (int(state[0]) , int(state[1])) )
	print(state_out)
	print( "Sending state: " + state )

	return

def set_state_enabled():
	global current_state
	global current_state_str
	global working

	current_state     = STATE_ENABLED
	current_state_str = STATE_ENABLED_STR

	notify_de_board( STATE_ENABLED_STR )

	red_led.set_low()
	green_led.set_low()
	yellow_led.set_high()

	working.play()

	return

def set_state_triggered():
	global current_state
	global current_state_str
	global alarm

	current_state     = STATE_TRIGGERED
	current_state_str = STATE_TRIGGERED_STR

	notify_de_board( STATE_TRIGGERED_STR )

	red_led.set_high()
	green_led.set_low()
	yellow_led.set_low()

	alarm.play(loops=-1)

	return

def set_state_standby():
	global current_state
	global current_state_str
	global alarm
	current_state     = STATE_STANDBY
	current_state_str = STATE_STANDBY_STR

	notify_de_board( STATE_STANDBY_STR )

	alarm.stop()
	red_led.set_low()
	green_led.set_high()
	yellow_led.set_low()
	return

def check_state_change():
	global state_in
	global current_state
	global current_state_str

	bit_1 = GPIO.input( state_in[0] )
	bit_2 = GPIO.input( state_in[1] )

	state = str(bit_1) + str(bit_2)

	if state == current_state_str:
		return
	
	if state == STATE_STANDBY_STR:
		set_state_standby()
		beeper.pulse(0.5)
	elif current_state == STATE_ENABLED and state == STATE_TRIGGERED_STR:
		set_state_triggered()
	elif current_state == STATE_STANDBY and state == STATE_ENABLED_STR:
		beeper.pulse( 0.1 )
		time.sleep( 0.5 )
		beeper.pulse( 0.1 )
		time.sleep( 0.5 )
		beeper.pulse( 0.1 )
		time.sleep( 0.5 )

		set_state_enabled()

		beeper.pulse( 1 )
	return

#---------------------------------------------------------------------
# Button Change Callbacks
#---------------------------------------------------------------------

def on_change_a():
	"""
	---------------------------------------
	Puts the system in enabled
	---------------------------------------
	"""
	if( current_state == STATE_STANDBY ):
		beeper.pulse( 0.1 )
		time.sleep( 0.5 )
		beeper.pulse( 0.1 )
		time.sleep( 0.5 )
		beeper.pulse( 0.1 )
		time.sleep( 0.5 )

		set_state_enabled()

		beeper.pulse( 1 )
	return
		

def on_change_b():
	"""
	---------------------------------------
	Puts the system in standby
	---------------------------------------
	"""
	global current_state
	if( current_state != STATE_STANDBY ):
		set_state_standby()

		beeper.pulse(0.5)
	return

#---------------------------------------------------------------------
# Sensor Checks
#---------------------------------------------------------------------

# These are glorified static variables. 
prev_time  = 0
ultrasonic_queue=[]

def check_ultrasonic():
	global current_state
	global prev_time
	global ultrasonic_queue

	trigger.set_high()
	time.sleep(0.0001)
	trigger.set_low()

	while not GPIO.input( PIN_HCSR04_ECHO ):
		start = time.time()

	while GPIO.input( PIN_HCSR04_ECHO ):
		stop = time.time()

	current_time = stop - start
	delta = abs(current_time - prev_time)

	
	ultrasonic_queue.append(delta)
	if len(ultrasonic_queue) > ULTRASONIC_QUEUE_SIZE:
		ultrasonic_queue.pop(0)
	

	if (current_state == STATE_ENABLED) and (median(ultrasonic_queue) >  ULTRASONIC_THRESHOLD):
		print("Ultrasonic Triggered: {}".format(delta))
		set_state_triggered()


	print("Ultrasonic Value : {:.5f} (Median: {:.5f})".format(delta, median(ultrasonic_queue)) )

	prev_time = current_time
	return

prev_pressure  = 0
def check_pressure( adc ):
	global current_state
	global prev_pressure

	val = adc.receive( MCP3008.CHANNEL0, MCP3008.DIFF_CH0_TO_CH1 )	
	delta = abs(val - prev_pressure)

	if (current_state == STATE_ENABLED) and (delta > PRESSURE_THRESHOLD):
		print("Pressure Triggered: {}".format(delta))
		set_state_triggered()	

	prev_pressure = val
	return

def median(lst):
	sortedLst=sorted(lst)
	lstLen=len(lst)
	index=(lstLen-1)//2
	if(lstLen%2):
		return sortedLst[index]
	else:
		return(sortedLst[index]+sortedLst[index+1])/2.0



#---------------------------------------------------------------------
# Main
#---------------------------------------------------------------------

radio_a.set_on_rising( on_change_a )
radio_b.set_on_rising( on_change_b )
#state_in.set_on_rising( on_state_change )
#state_in.set_on_falling( on_state_change )

try:
	check_ultrasonic() # Initialize ultrasonic sensor
	check_pressure( adc )

	while True:

		check_pressure( adc )
		# Check pressure sensor twice for every 1 ultrasonic
		check_ultrasonic()		
		time.sleep( SLEEP_TIME )
		check_ultrasonic()
		time.sleep( SLEEP_TIME )
		check_state_change()

		

except KeyboardInterrupt:
	GPIO.cleanup( [PIN_HCSR04_ECHO] )
	GPIO.cleanup( state_out )
	GPIO.cleanup( state_in )
	pass
