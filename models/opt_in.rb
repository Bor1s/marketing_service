class OptIn
  include Mongoid::Document
  belongs_to :channel

  field :email
  field :mobile
  field :first_name
  field :last_name
end
