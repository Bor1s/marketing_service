class Channel
  include Mongoid::Document
  belongs_to :company
  has_one :opt_in, dependent: :destroy
  field :name
end
