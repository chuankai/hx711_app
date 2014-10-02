#!/usr/bin/ruby

require 'sinatra'
require 'erubis'
require_relative 'calibration'

configure do
	@calib = Calibration.instance
end

def get_raw
	IO.read("/sys/bus/platform/drivers/hx711/raw")
end

def read_calibrated_value
end

set :bind, '0.0.0.0'

get '/' do 
	erb :index, :locals => {:gram => get_raw}
end

get '/calibration' do
	erb :calibration
end

get '/calibration/:name' do |gram|
	if (gram == '0')
		calib.clear_calibration_data
	end
	if calib.add_value_raw?(gram.to_i, read_raw.to_i)
		erb :calibration_done
	else
		erb :calibration
	end
end

get '/calibration_done' do
	erb :calibration_done
end
