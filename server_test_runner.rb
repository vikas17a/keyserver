require File.expand_path '../server_test.rb', __FILE__

describe "My Sinatra Application" do
  it "should allow generating key" do
    get '/gen_key'
    expect(last_response.status).to eq 200
  end

  it "should allocate key to the user" do
  	get '/allocate'
  	expect(last_response.status).to eq 200
  end

  it "should give 404 if no key available" do
  	get '/allocate'
  	expect(last_response.status).to eq 404
  end

  it "should give invalid key on deleting an deletable key" do
  	get '/delete_key/aresegaerASFA231'
  	expect(last_response.body).to eq '{Invalid Key}'
  end

  it "should give 404 on any other url" do
  	get '/sdfsdf'
  	expect(last_response.status).to eq 404
  end

  it "should give invalid key if keep alive comes for a non valid key" do
  	get '/keep_key/SF32432sefgsd32'
  	expect(last_response.body).to eq 'Invalid Key'
  end

  it "should give invalid key if unblock end point is triggered for some absurd key" do
  	get '/release_key/234234234234sdfa'
  	expect(last_response.body).to eq 'Invalid Key'
  end

end