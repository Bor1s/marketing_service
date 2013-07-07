require_relative 'server'

Rack::Handler::Thin.run Server.app
