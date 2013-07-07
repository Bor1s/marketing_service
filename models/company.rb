class Company
  include Mongoid::Document
  has_many :channels, dependent: :destroy
  field :name
end
