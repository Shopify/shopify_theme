module ShopifyTheme
  class APIChecker
    class APIResult
      OK = 200
      UNAUTHORIZED = 401
      SERVER_ERROR_CODES = (500..599)
      
      attr_reader :response
      def initialize(http_response)
        @response = http_response
      end

      def accessed_api?
        response.code == OK
      end

      def cannot_access_api?
        !accessed_api?
      end

      def invalid_config?
        response.code == UNAUTHORIZED
      end

      def api_down?
        SERVER_ERROR_CODES.include?(response.code)
      end
    end

    def initialize(client)
      @client = client
    end

    def test_connectivity
      return APIResult.new(client.get_index)
    end

    private
    attr_reader :client
  end
end
