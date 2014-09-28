require 'sinatra'
require 'erubis'

get '/' do 
	erb :index 
end

get '/calibration' do
	erb :calibration
end
