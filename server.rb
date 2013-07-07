require 'mongoid'
require 'rack'

ENV["MONGOID_ENV"] = "development"
Mongoid.load!('./config/mongoid.yml')
Dir.glob(File.join('./models','*.rb')).each {|f| require f}

# Rack app
class CompanyValidator
  def initialize(app)
    @app = app
  end

  def call(env)
    req = Rack::Request.new env
    company = Company.where(id: req.params['company_id']).first

    if company
      @app.call(env)
    else
      resp = Rack::Response.new
      resp['Content-Type'] = 'application/json'
      resp.status = 403
      answer = {success: false, message: 'Please provide valid company id'}.to_json
      resp.write answer
      resp.finish
    end
  end
end

class ChannelValidator
  def initialize(app)
    @app = app
  end

  def call(env)
    req = Rack::Request.new env
    resp = Rack::Response.new
    resp['Content-Type'] = 'application/json'

    channel = Channel.where(id: req.params["channel_id"]).first

    if channel
      @app.call(env)
    else
      resp = Rack::Response.new
      resp['Content-Type'] = 'application/json'
      resp.status = 403
      answer = {success: false, message: 'Please provide valid channel id'}.to_json
      resp.write answer
      resp.finish
    end
  end
end

class OptInValidator
  def initialize(app)
    @app = app
  end

  def call(env)
    req = Rack::Request.new env
    resp = Rack::Response.new
    resp['Content-Type'] = 'application/json'

    opt_in = OptIn.where(id: req.params["opt_in_id"]).first

    if opt_in
      @app.call(env)
    else
      resp = Rack::Response.new
      resp['Content-Type'] = 'application/json'
      resp.status = 403
      answer = {success: false, message: 'Please provide valid opt_in id'}.to_json
      resp.write answer
      resp.finish
    end
  end
end

class EnsurePost
  def initialize(app)
    @app = app
  end

  def call(env)
    req = Rack::Request.new env
    if req.post?
      @app.call(env)
    else
      resp = Rack::Response.new
      resp['Content-Type'] = 'application/json'
      resp.status = 403
      answer = {success: false, message: 'POST request allowed only'}.to_json
      resp.write answer
      resp.finish
    end
  end
end

class Server
  def self.app

    Rack::Builder.app do
      use Rack::Lint
      map "/companies" do
        run lambda { |env|
          resp = Rack::Response.new
          resp['Content-Type'] = 'application/json'
          answer = {success: true, companies: Company.all.map {|c| {id: c.id, name: c.name}} }.to_json
          resp.write answer
          resp.finish
        }
      end

      map "/channels" do
        use CompanyValidator
        run lambda { |env|
          req = Rack::Request.new env
          resp = Rack::Response.new
          resp['Content-Type'] = 'application/json'
          company = Company.where(id: req.params['company_id']).first

          answer = {success: true, channels: company.channels.map {|c| {id: c.id, name: c.name}} }.to_json
          resp.write answer
          resp.finish
        }
      end

      map "/opt_ins" do
        use CompanyValidator
        run lambda { |env|
          req = Rack::Request.new env
          resp = Rack::Response.new
          resp['Content-Type'] = 'application/json'

          company = Company.where(id: req.params['company_id']).first
          answer = {success: true, opt_ins: company.channels.map(&:opt_in).compact}.to_json
          resp.write answer
          resp.finish
        }
      end

      map "/opt_ins/new" do
        use ChannelValidator
        use EnsurePost

        run lambda { |env|
          req = Rack::Request.new env
          opt_params = req.params['opt_in'] || {} #To avoid exception
          resp = Rack::Response.new
          resp['Content-Type'] = 'application/json'

          channel = Channel.where(id: req.params["channel_id"]).first

          if channel.opt_in
            answer = {success: false, message: 'Opt In already exists in this channel'}.to_json
            resp.write answer
          else
            opt_in = channel.create_opt_in(first_name: opt_params['first_name'],
                                  last_name: opt_params['last_name'],
                                  email: opt_params['email'],
                                  mobile: opt_params['mobile'])
            answer = {success: true, opt_in: opt_in}.to_json
            resp.write answer
          end
          resp.finish
        }
      end

      map "/opt_ins/edit" do
        use OptInValidator
        use EnsurePost

        run lambda { |env|
          req = Rack::Request.new env
          opt_params = req.params['opt_in'] || {} #To avoid exception
          resp = Rack::Response.new
          resp['Content-Type'] = 'application/json'

          opt_in = OptIn.where(id: req.params["opt_in_id"]).first

          opt_in.first_name = opt_params['first_name']
          opt_in.last_name = opt_params['last_name']
          opt_in.email = opt_params['email']
          opt_in.mobile = opt_params['mobile']
          opt_in.save

          answer = {success: true, opt_in: opt_in}.to_json
          resp.write answer
          resp.finish
        }
      end

      #NOTE: Not sure about deactivating functionality :(
      map "/opt_ins/deactivate" do
        use OptInValidator
        use EnsurePost

        run lambda { |env|
          req = Rack::Request.new env
          resp = Rack::Response.new
          resp['Content-Type'] = 'application/json'

          opt_in = OptIn.where(id: req.params["opt_in_id"]).first
          opt_in.destroy
          answer = {success: true}.to_json
          resp.write answer
          resp.finish
        }
      end

      map "/restore_test_data" do
        run lambda { |env|
          req = Rack::Request.new env
          resp = Rack::Response.new
          resp['Content-Type'] = 'application/json'
          if req.params["test"]
            ENV["MONGOID_ENV"] = "test"
            load File.expand_path("../seeds.rb", __FILE__)
          end
          resp.write ""
          resp.finish
        }
      end
    end

  end
end
