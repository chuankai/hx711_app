!#/usr/bin/ruby

require 'eventmachine'
require 'singleton'
require 'date'
require_relative 'calibration'

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
		@state = LoggerState::DISABLED
		@freq = 30
		@mail_notification = false
		@mail_address = ''
	end

	def config(frequency=30, enable_mail_notification=false, mail_address='')
		@freq = frequency
		@mail_notification = enable_mail_notification
		@mail_address = mail_address
	end

	def start
		name = Date.today.to_s + '.txt'
		begin
			f= File.open(name, 'a');
		rescue
			puts 'File open failed'
		end
		if (@state == LoggerState::DISABLED)
			EM.run do
				EM.add_periodic_timer(@freq) do
					if @state == LoggerState::ENABLED_STOPPED
						EM.stop_event_loop
						@state = LoggerState::DISABLED
					end

					if name != Date.today.to_s + '.txt'
						f.close
						send_mail(name + '.txt') if @mail_notification
						name = Date.today.to_s
						begin
						f = File.open(name + '.txt', 'a')
						rescue
						puts 'File opne failed'
						end
					end
					gram = Calibration.instance.value_from_raw(IO.read('/sys/bus/platform/drivers/hx711/raw').to_i)
					if gram.class == Float
						gram = gram.round(2)
					end
					f.puts "#{Time.now.secs_of_today} #{gram}"
				end
			end
			@state = LoggerState::ENABLED_RUNNING
		end
	end

	def stop
		@state == LoggerState::ENABLED_STOPPED if @state == LoggerState::ENABLED_RUNNING
	end

	def send_mail
		puts 'send_mail'
	end
end
