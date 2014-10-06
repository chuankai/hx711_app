!#/usr/bin/ruby

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
		@interval = 30
		@mail_notification = false
		@mail_address = ''
	end

	def config(interval=30, enable_mail_notification=false, mail_address='')
		@interval = interval
		@mail_notification = enable_mail_notification
		@mail_address = mail_address
	end

	def start
		name = Date.today.to_s + '.txt'
		begin
			f= File.open('log/' + name, 'a');
		rescue
			puts 'File open failed'
		end
		if (@state == LoggerState::DISABLED)
			Thread.new do
				@state = LoggerState::ENABLED_RUNNING
				loop do
					if @state == LoggerState::ENABLED_STOPPED
						f.flush
						@state = LoggerState::DISABLED
						break
					end

					if name != Date.today.to_s + '.txt'
						f.close
						send_mail(name + '.txt') if @mail_notification
						name = Date.today.to_s
						begin
						f = File.open('log/' + name + '.txt', 'a')
						rescue
						puts 'File opne failed'
						end
					end
					gram = Calibration.instance.value_from_raw(IO.read('/sys/bus/platform/drivers/hx711/raw').to_i)
					gram = gram.round(2)
					f.puts "#{Time.now.secs_of_today} #{gram}"
					sleep(@interval)
				end
			end
		end
	end

	def stop
		@state == LoggerState::ENABLED_STOPPED if @state == LoggerState::ENABLED_RUNNING
	end

	def send_mail
		puts 'send_mail'
	end
end
