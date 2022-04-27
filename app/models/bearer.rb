class Bearer < ApplicationRecord
  has_many :stocks

  validates :name, presence: true, uniqueness: true
end
