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
	attr_reader :time_to_delete_key
  attr_reader :time_to_unblock_key
	
	def initialize
		@available_keys = {}
		@key_status = {} 
		@key_alive_status = {}
    @time_to_unblock_key = 60
    @time_to_delete_key = 300
	end

	def gen_key
		key = SecureRandom.urlsafe_base64
		@available_keys[key] = true
		@key_status[key] = 'ub'
		@key_alive_status[key] = Time.now.getutc
		puts "#{key} is generated".green
	end
	
	def allot_key
		if @available_keys.length == 0
			raise RuntimeError, "404"
		end
		key, value = available_keys.get_rand_pair
		@key_status[key] = 'b'
		@key_alive_status[key] = Time.now.getutc
		@available_keys.delete(key)
		puts "#{key} is allocated to user".green
		"#{key}"
	end

	def release_key(key)
		if @key_status[key] == nil
			return "Invalid Key"
		elsif @key_status[key] == 'ub'
      return "Already released"
    end
		@key_status[key] = 'ub'
		@available_keys[key] = true
		puts "#{key} is unblocked".blue
		"#{key} unblocked"
	end

	def delete_key!(key)
		if @key_status[key] == nil
			return "Invalid Key"
		end
		@key_status.delete(key)
		if @available_keys[key]
			@available_keys.delete(key)
		end
		@key_alive_status.delete(key)
		puts "#{key} is deleted".red
		"#{key} deleted"
	end

	def keep_alive(key)
		if @key_status[key] == nil
			return "Invalid Key"
		end
		@key_alive_status[key] = Time.now.getutc
		puts "Alive request for #{key} recieved".yellow
	end

	def purge_key
		time = Time.now.getutc
		@key_alive_status.each do |key, value|
			if (time-value) >= @time_to_delete_key
				delete_key!(key)
			end
		end	
	end

	def unblock_key
		time = Time.now.getutc
		@key_alive_status.each do |key, value|
			if (time - value) >= @time_to_unblock_key
        release_key(key)
			end
		end
	end

  def time_reset(delete,unblock)
    @time_to_unblock_key = unblock
    @time_to_delete_key = delete
  end

end

class Schedule
	attr_reader :scheduler
	attr_reader :api
  attr_reader :timer_to_purge_key
  attr_reader :timer_to_release_key

	def initialize(api)
		@scheduler = Rufus::Scheduler.new
		@api = api
    @timer_to_purge_key = '1m'
    @timer_to_release_key = '5s'
	end

	def start_scheduler
		@scheduler.every @timer_to_purge_key do
			begin
				@api.purge_key
			rescue
				raise "Error in starting delete key scheduler"
			end
		end

		@scheduler.every @timer_to_release_key do
			begin
			@api.unblock_key
			rescue
				raise "Error in starting unblock key scheduler"
			end
		end
	end

  def reset_scheduler(purge, release)
    @timer_to_purge_key = purge
    @timer_to_release_key = release
  end

  def shut_down_scheduler
  	@scheduler.shutdown(:kill)
  end

end