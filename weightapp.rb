#!/usr/bin/ruby

require 'sinatra'
require 'erubis'
require_relative 'calibration'
require_relative 'weight_log.rb'

configure do
	set :calib, Calibration.instance
	enable :static

	begin
		File.open('/sys/bus/platform/drivers/hx711/power', 'r+') do |f|
			f.puts '1'
		end
	rescue
		puts 'Failed to open sysfs'
	end

	WeightLogger.instance.config(30, true, 'anilyang.tw@gmail.com')
	WeightLogger.instance.start
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
	erb :calibration
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
		erb :calibration
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
