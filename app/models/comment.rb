class Comment < ApplicationRecord
  validates :body, presence: true, length: { maximum: 2000 }
end
