require 'sinatra'
require 'erubis'

get '/' do 
	erb :index 
end

get '/calibration' do
	erb :calibration
end

get '/calibration/:name' do |gram|
	gram
end
