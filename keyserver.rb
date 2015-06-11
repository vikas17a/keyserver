require 'sinatra'
require 'securerandom'
require 'json'
require 'rufus-scheduler'
require 'colorize'

class Hash
	def get_rand_pair
		key = self.keys[rand(self.length)]
     	[key, self[key]]
	end
end

class Api
	attr_reader :available_keys
	attr_reader :key_status
	attr_reader :key_alive_status
	attr_reader :time_delete        ##config variable
  attr_reader :time_unblock       ##config variable   
	
	def initialize
		@available_keys = {}            #### keyStatus for mapping key with its status ####
		@key_status = {}                #### ub for UnBlock and b for Block ####  
		@key_alive_status = {}
    @time_unblock = 60
    @time_delete = 300
	end

	def gen_key                         ##### E1 generating a key ##### 
		begin
			key = SecureRandom.urlsafe_base64
			@available_keys[key] = true
			@key_status[key] = 'ub'
			@key_alive_status[key] = Time.now.getutc
			puts "#{key} is generated".green
		rescue
			raise "Error in generating key"
		end
	end
	
	def allot_key                        ##### E2 allocating a key #####
		if available_keys.length == 0
			raise RuntimeError, "404"
		end
		begin
			key, value = available_keys.get_rand_pair
			@key_status[key] = 'b'
			@key_alive_status[key] = Time.now.getutc
			@available_keys.delete(key)
			puts "#{key} is allocated to user".green
			key
		rescue
			raise "Error in allocating a key"
		end
	end

	def release_key(key)                 ##### E3 unblocking a key #####
		begin
			if @key_status[key] == nil
				return "Invalid Key"
			elsif @key_status[key] == 'ub'
        return "Already released"
      end
			@key_status[key] = 'ub'
			@available_keys[key] = true
			puts "#{key} is unblocked".blue
			"#{key} unblocked"
		rescue
			raise "Error in releasing a key"
		end
	end

	def delete_key(key)					##### E4 deleting a key ######
		begin
			if @key_status[key] == nil
				return "{Invalid Key}"
			end
			@key_status.delete(key)
			@available_keys.delete(key)
			@key_alive_status.delete(key)
			puts "#{key} is deleted".red
			"#{key} deleted"
		rescue
			raise "Error in deleting a key"
		end
	end

	def keep_alive(key)                 ##### E5 keep alive request ####
		begin
			if @key_status[key] == nil
				return "Invalid Key"
			end
			@key_alive_status[key] = Time.now.getutc
			puts "Alive request for #{key} recieved".yellow
		rescue
			raise "Error in keeping alive a key"
		end
	end

	def purge_key
		begin
			time = Time.now.getutc
			@key_alive_status.each do |key, value|
				if (time-value) >= @time_delete
					delete_key(key)
				end
			end
		rescue
			raise "Error in purgin key (automated)"
		end
	end

	def unblock_key
		begin
			time = Time.now.getutc
			@key_alive_status.each do |key, value|
				if (time - value) >= @time_unblock
          release_key(key)
				end
			end
		rescue
			raise "Error in unblocking a key"
		end
	end

  def time_reset(delete,unblock)
    @time_unblock = unblock
    @time_delete = delete
  end

end

class Schedule
	attr_reader :scheduler
	attr_reader :api 
  attr_reader :purge_time
  attr_reader :release_time
	def initialize(api)
		@scheduler = Rufus::Scheduler.new
		@api = api
    @purge_time = '1m'
    @release_time = '5s'
	end
	def start
		@scheduler.every @purge_time do              ##Scheduler scheduling deleting for every 1m## 
			begin
				@api.purge_key
			rescue
				raise "Error in scheduler"
			end
		end
		@scheduler.every @release_time do              ##Scheduler scheduling unblocker for every 5s##
			begin
			@api.unblock_key
			rescue
				raise "Error in scheduler"
			end
		end
	end
  def reset_scheduler(purge, release)
    @purge_time = purge
    @release_time = release
  end
  def shut_down
  	@scheduler.shutdown(:kill)
  end
end