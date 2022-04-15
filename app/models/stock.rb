class Stock < ApplicationRecord
  belongs_to :bearer

  def self.current
    where(deleted_at: nil)
  end

  def soft_delete!
    update!(deleted_at: DateTime.current)
  end

  def destroy
    soft_delete!
  end
end
