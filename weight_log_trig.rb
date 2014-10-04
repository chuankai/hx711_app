!#/usr/bin/ruby

require 'eventmachine'
require 'calibration'
require 'singleton'
require 'date'

class WeightLogger
	include Singleton

	def initialize
		Dir.mkdir('log') unless Dir.exists?('log')
		@enabled = false
	end

	def config(frequency, duration, enable_mail_notification, mail_address) 
		@freq = frequency
		@duration = duration
		@mail_notification = enable_mail_notification
		@mail_address = mail_address
	end

	def start
		if (!@enabled)
			EM.run do
				@timer_stopped = false
				EM.add_periodic_timer(@freq) do
					if @timer_stopped
						EM.stop_event_loop
						@enabled = false
					end

					name = Date.today.to_s + '.txt'
					begin
					File.open(name, "a") do |f|
						gram = Calibratin.instance.value_from_raw(IO.read('/sys/bus/platform/drivers/hx711/raw'))
						file.puts("#{time} #{gram}")
					end
					rescue
					puts 'File open failed'
					end
				end
			end
			@enabled = true
		end
	end

	def stop
		@timer_stopped = true
	end
end



class WeightTrigger
	include Singleton
end