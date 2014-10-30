!#/usr/bin/ruby

require 'singleton'
require 'date'
require 'mail'
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
		@state = LoggerState::DISABLED
		@interval = 30
		@mail_notification = false
		@mail_address = ''
		@f = nil

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

	def config(interval=30, enable_mail_notification=false, mail_address='')
		@interval = interval
		@mail_notification = enable_mail_notification
		@mail_address = mail_address
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
			Thread.new do
				@state = LoggerState::ENABLED_RUNNING
				loop do
					if @state == LoggerState::ENABLED_STOPPED
						@f.flush
						@state = LoggerState::DISABLED
						break
					end

					if name != Date.today.to_s + '.txt'
						@f.close
						send_log(name + '.txt') if @mail_notification
						name = Date.today.to_s
						begin
						@f = File.open('public/' + name + '.txt', 'a')
						rescue
						puts 'File open failed'
						end
					end
					gram = Calibration.instance.value_from_raw(IO.read('/sys/bus/platform/drivers/hx711/raw').to_i)
					gram = gram.round(2)
					@f.puts "#{Time.now.secs_of_today} #{gram}"
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
		@f.flush
	end
end
