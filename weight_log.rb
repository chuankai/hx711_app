!#/usr/bin/ruby

require 'eventmachine'
require 'calibration'
require 'singleton'
require 'date'

module LoggerState
	DISABLED = 1
	ENABLED_STOPPED = 2
	ENABLED_RUNNING = 3
end

class Time
	def secs_of_today
		(hour * 60 + min) * 60 + sec
	end
end

class WeightLogger
	include Singleton

	def initialize
		Dir.mkdir('log') unless Dir.exists?('log')
		@state = LoggerState.DISABLED
	end

	def config(frequency, duration, enable_mail_notification, mail_address) 
		@freq = frequency
		@duration = duration
		@mail_notification = enable_mail_notification
		@mail_address = mail_address
	end

	def start
		name = Date.today.to_s
		begin
			f= File.open(name, 'a');
		rescue
			puts 'File open failed'
		end
		if (@state == LoggerState.DISABLED)
			EM.run do
				@timer_stopped = false
				EM.add_periodic_timer(@freq) do
					if @state == LoggerState.ENABLED_STOPPED
						EM.stop_event_loop
						@state = LoggerState.DISABLED
					end

					if name != Date.today.to_s
						f.close
						send_mail(name + '.txt') if @mail_notification
						name = Date.today.to_s
						begin
						f = File.open(name + '.txt', 'a')
						rescue
						puts 'File opne failed'
						end
					end
					gram = Calibratin.instance.value_from_raw(IO.read('/sys/bus/platform/drivers/hx711/raw'))
					f.puts "#{Time.now.secs_of_today} #{gram}"
				end
			end
			@state = LoggerState.ENABLED_RUNNING
		end
	end

	def stop
		@timer_stopped = true
	end

	def send_mail
		puts 'send_mail'
	end
end



class WeightTrigger
	include Singleton
end
