module V1
  class Stocks < Grape::API
    include API::V1::Defaults

    before { require_access_token! }

    helpers do
      def stock
        Stock.current.find(params[:id])
      end

      def handle_bearer_in_params!
        if permitted_params[:bearer_name].present?
          bearer_id = Bearer.find_or_create_by(name: permitted_params[:bearer_name]).id

          permitted_params.tap do |params|
            params.delete(:bearer_name)
            params.merge!(bearer_id:)
          end
        end
      end
    end

    resource :stocks do
      desc 'Return all stocks'
      get '', root: :stocks do
        Stock.current
      end

      desc 'Create a new stock'
      params do
        requires :name, type: String, desc: 'Name of the stock'
        requires :bearer_id, type: Integer, desc: 'ID of referenced Bearer'
      end
      post do
        bearer = Bearer.find(permitted_params[:bearer_id])
        Stock.create!(name: permitted_params[:name], bearer: bearer)
      end

      desc 'Update a stock'
      params do
        optional :name, type: String, desc: 'Name of the stock'
        optional :bearer_name, type: String, desc: 'Bearer name for the stock'
      end

      route_param :id do
        put do
          handle_bearer_in_params!

          stock.update(permitted_params)

          stock
        end
      end

      desc 'Delete a specific stock'
      params { requires :id }

      route_param :id do
        delete do
          stock.destroy

          status 204
        end
      end
    end
  end
end
