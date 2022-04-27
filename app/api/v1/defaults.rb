module V1
  module Defaults
    extend ActiveSupport::Concern

    included do
      prefix 'api'
      version 'v1', using: :path
      default_format :json
      format :json
      formatter :json, Grape::Formatter::ActiveModelSerializers

      helpers do
        def permitted_params
          @permitted_params ||= declared(params, include_missing: false)
        end

        def logger
          Rails.logger
        end

        def require_access_token!
          raise Exceptions::Unauthorized.new('Invalid Bearer token') unless valid_bearer_token?
        end

        private

        def valid_bearer_token?
          return @valid_bearer_token if defined? (@valid_bearer_token)
          @valid_bearer_token = access_token.present?
        end

        def access_token
          @access_token ||= request.headers.fetch('Authorization', '').gsub('Bearer ', '')
        end

        def render_error(message:, status:)
          logger.error message
          error!({ error: message }, status)
        end
      end

      rescue_from ActiveRecord::RecordNotFound do |e|
        render_error(message: e.message, status: 404)
      end

      rescue_from ActiveRecord::RecordInvalid do |e|
        render_error(message: e.message, status: 422)
      end

      rescue_from Exceptions::Unauthorized do |e|
        render_error(message: e.message, status: 401)
      end

      rescue_from Grape::Exceptions::ValidationErrors do |e|
        render_error(message: e.message, status: 400)
      end

      rescue_from :all do |e|
        render_error(message: "Internal Server Error \n #{e.message}", status: 500)
      end
    end
  end
end
