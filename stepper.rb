!#/usr/bin/ruby

require 'wiringpi'

class Stepper
	def initialize(pin1, pin2, pin3, pin4, interval) 
		@gpio = WiringPi::GPIO.new 
		@pin1 = pin1
		@pin2 = pin2
		@pin3 = pin3
		@pin4 = pin4
		@interval = interval
		@running = false

		@gpio.mode(pin1, OUTPUT)
		@gpio.mode(pin2, OUTPUT)
		@gpio.mode(pin3, OUTPUT)
		@gpio.mode(pin4, OUTPUT)

		@gpio.write(@pin1, 0)
		@gpio.write(@pin2, 0)
		@gpio.write(@pin3, 0)
		@gpio.write(@pin4, 0)

		@worker = Thread.new {
			while true
				unless @running
					@gpio.write(@pin1, 0)
					@gpio.write(@pin2, 0)
					@gpio.write(@pin3, 0)
					@gpio.write(@pin4, 0)
					puts 'Stopping Worker thread'
					Thread.stop
				end

				puts 'Worker thread running'
				@gpio.write(@pin1, 1)
				@gpio.write(@pin2, 0)
				@gpio.write(@pin3, 0)
				@gpio.write(@pin4, 0)
				sleep @interval 

				@gpio.write(@pin1, 0)
				@gpio.write(@pin2, 0)
				@gpio.write(@pin3, 0)
				@gpio.write(@pin4, 1)
				sleep @interval 

				@gpio.write(@pin1, 0)
				@gpio.write(@pin2, 1)
				@gpio.write(@pin3, 0)
				@gpio.write(@pin4, 0)
				sleep @interval 

				@gpio.write(@pin1, 0)
				@gpio.write(@pin2, 0)
				@gpio.write(@pin3, 1)
				@gpio.write(@pin4, 0)
				sleep @interval 
			end
		}
	end

	def run
		@running = true
		@worker.wakeup
	end

	def stop
		puts 'Stepper stop'
		@running = false
	end

	def setInterval(interval)
		@interval = interval
	end

	def test(pin1, pin2, pin3, pin4)
				@gpio.write(@pin1, pin1)
				@gpio.write(@pin2, pin2)
				@gpio.write(@pin3, pin3)
				@gpio.write(@pin4, pin4)
	end
end


