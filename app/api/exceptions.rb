module Exceptions
  class Unauthorized < StandardError
    def initialize(msg = 'Unauthorized')
      super
    end
  end
end
