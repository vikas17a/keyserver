require 'sinatra'
require './keyserver.rb'

api = Api.new
scheduler = Schedule.new(api)
scheduler.start_scheduler

get '/gen_key' do
	begin 
		api.gen_key
	rescue
		"Error in generating key"
	end
	"Ok"
end

get '/allocate' do
	begin
		res = api.allot_key
	rescue
		status 404
	end
	"#{res}"
end

get '/release_key/?:key' do
	begin
		api.release_key(params['key'])
	rescue
		"Error in releasing key"
	end
end

get '/delete_key/?:key' do
	begin
		api.delete_key!(params['key'])
	rescue
		"Error in deleting key"
	end
end

get '/keep_key/?:key' do
	begin
		api.keep_alive(params['key'])
	rescue
		"Error in keep alive key"
	end
end
