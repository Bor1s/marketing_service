require_relative '../server'
require 'rack/test'

Mongoid.load!('./config/mongoid.yml')
Dir.glob(File.join('./models','*.rb')).each {|f| require f}
