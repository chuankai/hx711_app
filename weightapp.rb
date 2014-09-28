require 'sinatra'
require 'erubis'
require './calibration'

calib = Calibration.instance

begin
	f = File.open("/sys/bus/platform/drivers/hx711/raw", "r")
rescue Exception => e
	puts 'Cannot opnen hx711/raw'
	puts e
end

def read_raw
	f.read
end

get '/' do 
	val = calib.value_from_raw(read_raw)
	erb :index, :locals => {:gram => val}
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
