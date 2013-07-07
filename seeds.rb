require 'mongoid'

ENV["MONGOID_ENV"] = "development"
Mongoid.load!('./config/mongoid.yml')
Dir.glob(File.join('./models','*.rb')).each {|f| require f}

Company.destroy_all

c = Company.create(name: 'Company1')
email     = c.channels.create(name: "email")
email.create_opt_in(email: 'foo@gmail.com',
                    first_name: "Frodo",
                    last_name: 'Baggins',
                    mobile: '1237628347823')

sms       = c.channels.create(name: "sms")
sms.create_opt_in(email: 'bar@gmail.com',
                    first_name: "Bilbo",
                    last_name: 'Baggins',
                    mobile: '1237628347823')

sms_email = c.channels.create(name: "sms+email")
sms_email.create_opt_in(email: 'baz@gmail.com',
                    first_name: "Folko",
                    last_name: 'Baggins',
                    mobile: '1237628347823')
