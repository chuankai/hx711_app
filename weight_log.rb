!#/usr/bin/ruby

require 'singleton'
require 'date'
require 'mail'
require_relative 'calibration'
require 'wiringpi'

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
	
	DRIVER_PIN = 0

	def initialize
		@state = LoggerState::DISABLED
		@interval = 30
		@max_val = 0
		@min_val = 0
		@mail_notification = false
		@mail_address = ''
		@f = nil
		@driver = WiringPi::GPIO.new
		@driver.mode(DRIVER_PIN, OUTPUT)
		@driver.write(DRIVER_PIN, 0)

		Mail.defaults do
			delivery_method :smtp, {:address              => "smtp.gmail.com",
						:port                 => 587,
						:domain               => 'kai.idv.tw',
						:user_name            => 'chuankai@kai.idv.tw',
						:password             => '23FrSw35',
						:authentication       => 'plain',
						:enable_starttls_auto => true}
		end
	end

	def config(interval, enable_mail_notification, mail_address, max_val, min_val)
		@interval = interval
		@mail_notification = enable_mail_notification
		@mail_address = mail_address
		@max_val = max_val
		@min_val = min_val
	end

	def start
		send_info if @mail_notification
		name = Date.today.to_s + '.txt'
		begin
			@f= File.open('public/' + name, 'a');
		rescue
			puts 'File open failed'
		end
		if (@state == LoggerState::DISABLED)
			puts 'about to create the thread'
			Thread.new do
				@state = LoggerState::ENABLED_RUNNING

				inputs = Array.new
				gram = 0
				queue = Array.new()
				3.times do
					queue << 1.0
				end
				trend_count = 0
				warning = ''
				loop do
					if @state == LoggerState::ENABLED_STOPPED
						@f.flush
						@state = LoggerState::DISABLED
						break
					end

					if name != Date.today.to_s + '.txt'
						puts 'A new day has begun'
						@f.close
						#send_log(name + '.txt') if @mail_notification
						name = Date.today.to_s
						begin
						@f = File.open('public/' + name + '.txt', 'a')
						rescue
						puts 'File open failed'
						end
					end
					inputs.clear
					1.upto 5 do
						inputs << Calibration.instance.value_from_raw(IO.read('/sys/bus/platform/drivers/hx711/raw').to_i).round(2)
						sleep(0.05)
					end
					inputs.sort!
					if inputs[2] == @max_val
						warning = 'higher than max'
					elsif inputs[2] == @min_val
						warning = 'lower than min'
					else
						gram = inputs[2]
						warning = ''
					end

					if queue.last - gram > 1
						trend_count += 1
					else
						trend_count = 0
					end

					if (queue.shift - gram > 20 && trend_count == 4)
						trend_count = 0
						@driver.write(DRIVER_PIN, 1)
						sleep(20)
						@driver.write(DRIVER_PIN, 0)
					end

					queue.push gram
					@f.puts "#{Time.now.secs_of_today} #{gram} #{warning}"
					sleep(@interval)
				end
			end
		end
	end

	def stop
		@state == LoggerState::ENABLED_STOPPED if @state == LoggerState::ENABLED_RUNNING
	end

	def send_log(file)
		addr = @mail_address
		mail = Mail.new do
			from 'chuankai@kai.idv.tw'
			#to 'anilyang.tw@gmail.com'
			to addr
			subject 'Cats drink water'
			body "Hi, \nYour cats have sent you the log file."
			add_file '/root/hx711_app/public/' + file
		end
		begin
			mail.deliver!
		rescue
			puts 'mail deliver failed'
		end
	end

	def send_info
		puts "email address: #{@mail_address}"
		ip_addr = `ifconfig`.match(/192\.\d{,3}\.\d{,3}\.\d{,3}/).to_s
		addr = @mail_address
		mail = Mail.new do
			from 'chuankai@kai.idv.tw'
			#to 'anilyang.tw@gmail.com'
			to addr
			subject 'Cats are ready to drink water'
			body "Hi, \nYour cats are ready to drink water. Check it out at	http://#{ip_addr}:4567" 
		end
		begin
			mail.deliver!
		rescue
			puts 'mail deliver failed'
		end
	end

	def flush_log
		@f.flush unless @f.closed?
	end
end
