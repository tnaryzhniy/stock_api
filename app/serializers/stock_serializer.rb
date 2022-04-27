class StockSerializer < ActiveModel::Serializer
  attributes :id, :name, :bearer_name

  def bearer_name
    object.bearer.name
  end
end
