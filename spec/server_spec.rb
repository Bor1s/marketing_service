require 'spec_helper'

describe Server do
  include Rack::Test::Methods

  # Redefine app method (rack test)
  def app
    Server.app
  end

  before :all do
    ENV["MONGOID_ENV"] = "test"
    Company.destroy_all
    @c = Company.create(name: 'Company1')
    @email     = @c.channels.create(name: "email")
    @email.create_opt_in(email: 'foo@gmail.com',
                        first_name: "Frodo",
                        last_name: 'Baggins',
                        mobile: '1237628347823')

    @sms       = @c.channels.create(name: "sms")
    @sms.create_opt_in(email: 'bar@gmail.com',
                        first_name: "Bilbo",
                        last_name: 'Baggins',
                        mobile: '1237628347823')

    @sms_email = @c.channels.create(name: "sms+email")
    @sms_email.create_opt_in(email: 'baz@gmail.com',
                        first_name: "Folko",
                        last_name: 'Baggins',
                        mobile: '1237628347823')
  end


  it '::app returns Rack::Lint instance' do
    app.class.should eq Rack::Lint
  end

  it 'returns companies JSON' do
    get '/companies'
    last_response.should be_ok
    expected_result = {success: true, companies: Company.all.map {|c| {id: c.id, name: c.name} }}
    last_response.body.should == expected_result.to_json
  end

  it 'returns channels JSON' do
    get "/channels?company_id=#{@c.id}"
    last_response.should be_ok
    expected_result = {success: true, channels: @c.channels.map {|c| {id: c.id, name: c.name} }}
    last_response.body.should == expected_result.to_json
  end

  it 'returns opt_ins JSON' do
    get "/opt_ins?company_id=#{@c.id}"
    last_response.should be_ok
    expected_result = {success: true, opt_ins: @c.channels.map(&:opt_in)}
    last_response.body.should == expected_result.to_json
  end

  context 'Managing Opt Ins' do
    it 'creates new opt in if not exists in channel' do
      @email.opt_in.destroy
      post "/opt_ins/new?channel_id=#{@email.id}&opt_in[first_name]=Frodo"
      last_response.should be_ok
      body = JSON.parse(last_response.body)
      body["success"].should be_true
      body["opt_in"]["first_name"].should eq 'Frodo'
    end

    it 'does not creates opt-in if already exists in current channel' do
      post "/opt_ins/new?channel_id=#{@email.id}&opt_in[first_name]=Frodo"
      last_response.should be_ok
      body = JSON.parse(last_response.body)
      body["success"].should be_false
    end

    it 'edits opt-in' do
      post "/opt_ins/edit?opt_in_id=#{@sms.opt_in.id}&opt_in[first_name]=Bilbo"
      last_response.should be_ok
      body = JSON.parse(last_response.body)
      body["success"].should be_true
      body["opt_in"]["first_name"].should eq 'Bilbo'
    end

    it 'deactivates opt-in' do
      post "/opt_ins/deactivate?opt_in_id=#{@sms.opt_in.id}"
      last_response.should be_ok
      body = JSON.parse(last_response.body)
      body["success"].should be_true
    end
  end
end
