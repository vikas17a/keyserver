require './keyserver.rb'

RSpec.configure do |config|
  config.color = true
  original_stderr = $stderr
  original_stdout = $stdout
  config.before(:all) do 
    # Redirect stderr and stdout
    $stderr = File.new(File.join(File.dirname(__FILE__), 'dev', 'null.txt'), 'w')
    $stdout = File.new(File.join(File.dirname(__FILE__), 'dev', 'null.txt'), 'w')
  end
  config.after(:all) do 
    $stderr = original_stderr
    $stdout = original_stdout
  end
end

RSpec.describe "Individual functions of Api" do
  before(:all) do
    @api = Api.new
    @schedule = Schedule.new(@api)
    @api.time_reset(10,2)
    @schedule.reset_scheduler('5s','1s')
  end

  it "start generating keys for api server" do
    40.times do
      @api.gen_key
    end
  end

  it "now allocating half of the keys to user" do
    10.times do
      @api.allot_key
    end
  end

  it "check if unblock background works" do
    sleep(12)
    expect(@api.available_keys.length).to be >= 30
  end

  it "check if keep alive key works" do
    20.times do
      @api.gen_key
    end
    @api.key_status.each do |key,value|
      @api.keep_alive(key)
    end
    @api.purge_key
    expect(@api.key_status.length).to be >= 20
  end

  it "check if delete background works" do
    @api.key_status.each do |key, value|
      @api.delete_key(key)
    end
    10.times do
      @api.gen_key
    end
    sleep(52)
    expect(@api.available_keys.length).to be <= 10
  end

  it "check if allocate key blocks the key or not" do
    @api.key_status.each do |key, value|
      @api.delete_key(key)
    end
    20.times do
      @api.gen_key
      @api.allot_key
    end
    expect(@api.available_keys.length).to be <= 20
    sleep(20)
  end

  it "check if unblock end point works" do
    @api.key_status.each do |key, value|
      @api.delete_key(key)
    end
    20.times do
      @api.gen_key
      @api.allot_key
    end
    @api.key_status.each do |key, value|
      if value == 'b'
        @api.release_key(key)
      end
    end
    expect(@api.available_keys.length).to be <= 20
  end
end

RSpec.describe "Functioning part" do
  before(:each) do
    @api = Api.new
    @schedule = Schedule.new(@api)
  end

  it "check if background key delete's on time for(unblocked keys)" do
    @api.time_reset(10,200)
    @schedule.reset_scheduler('1s','200s')
    @schedule.start
    20.times do
      @api.gen_key
    end
    sleep(20)
    expect(@api.key_status.length).to eq 0
    @schedule.shut_down
  end

  it "check if background key delete's on time for(blocked keys)" do
    @api.time_reset(2,200)
    @schedule.reset_scheduler('1s','200s')
    @schedule.start
    10.times do
      @api.gen_key
      @api.allot_key
    end
    sleep(20)
    expect(@api.key_status.length).to eq 0
    @schedule.shut_down
  end

  it "check if blocked key got unblocked delete first if delete time is smaller than unblock" do
    @api.time_reset(1,5)
    @schedule.reset_scheduler('1s','1s')
    @schedule.start
    10.times do
      @api.gen_key
      @api.allot_key
    end
    sleep(10)
    expect(@api.available_keys.length).to eq 0
    @schedule.shut_down
  end

  it "check when all keys are deleted then any key allocats or not", :runme => true do 
    @api.time_reset(10,5)
    @schedule.reset_scheduler('1s','200s')
    @schedule.start
    5.times do
      @api.gen_key
    end
    sleep(15)
    expect{@api.allot_key}.to raise_error(RuntimeError, "404")
    @schedule.shut_down
  end

  it "check if deleted key unblocks" do
    del_key = []
    @api.time_reset(40,40)
    @schedule.reset_scheduler('200s','200s')
    @schedule.start
    10.times do
      @api.gen_key
    end
    @api.available_keys.each do |key, value|
      @api.delete_key(key)
      del_key.push(key)
    end
    del_key.each do |val|
      expect(@api.release_key(val)).to eq "Invalid Key"
    end
    @schedule.shut_down
  end

  it "check if unblocks endpoint unblocks an already unblocked key" do
    @api.time_reset(30,2)
    @schedule.reset_scheduler(40,1)
    @schedule.start
    10.times do
      @api.gen_key
    end
    sleep(5)
    @api.available_keys.each do |key, value|
      expect(@api.release_key(key)).to eq "Already released"
    end
    @schedule.shut_down
  end

  it "check if any absurd key is entered for deletion" do
    @api.time_reset(100,100)
    @schedule.reset_scheduler('50s', '50s')
    expect(@api.delete_key('randomizedkey')).to eq "{Invalid Key}"
  end
end