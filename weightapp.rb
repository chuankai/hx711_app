#!/usr/bin/ruby

require 'sinatra'
require 'erubis'
require_relative 'calibration'
require_relative 'weight_log.rb'
require_relative 'stepper.rb'

configure do
	calib_gram_entries = [0, 400, 800, 1200, 1600, 2000, 2400, 2800]
	set :calib, Calibration.instance
	set :calib_gram, calib_gram_entries
	set :calib_index, 0
	set :stepper, stepper.new(0, 1, 2, 3, 0.01)
	enable :static

	begin
		File.open('/sys/bus/platform/drivers/hx711/power', 'r+') do |f|
			f.puts '1'
		end
	rescue
		puts 'Failed to open sysfs'
	end

	WeightLogger.instance.config(10, true, 'anilyang.tw@gmail.com', calib_gram_entries.last, calib_gram_entries.first)
	WeightLogger.instance.start
	Calibration.instance.num_of_entry = calib_gram_entries.length

end

def get_raw
	IO.read("/sys/bus/platform/drivers/hx711/raw")
end

def read_calibrated_value
end

set :bind, '0.0.0.0'

get '/' do 
	g = settings.calib.value_from_raw(get_raw.to_i)
	g = g.round(2)
	erb :index, :locals => {:gram => g.to_s,  :raw => get_raw}
end

get '/calibration' do
	settings.calib.clear_calibration_data
	settings.calib_index = 0
	erb :calibration, :locals => {:gram => settings.calib_gram[0]}
end

get '/calibration/:name' do |gram|
	raw = 0.0
	5.times do |i|
		raw += get_raw.to_f * 0.2
		sleep(0.05)
	end
	if (settings.calib.add_value_raw?(gram.to_i, raw.to_i))
		erb :calibration_done
	else
		settings.calib_index += 1
		erb :calibration, :locals => {:gram => settings.calib_gram[settings.calib_index]}
	end
end

get '/calibration_done' do
	erb :calibration_done
end

get '/log' do
	entries = Dir.entries("public").select! {|e| e.slice(-4..-1) == '.txt'}
	erb :log, :locals => {:entries => entries}
end

get '/log/:name' do
	WeightLogger.instance.flush_log
	redirect to("/#{params[:name]}")
end

get '/motor/test/:sec/:interval' do
	s = settings.stepper;
	s.setInterval(params[:interval].to_f)
	s.run
	sleep(params[:sec].to_f) 
	s.stop
end
		
