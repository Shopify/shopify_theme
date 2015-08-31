module ShopifyTheme
  class APIChecker
    class APIResult
      def initialize(http_response)
        @response = http_response
      end

      def accessed_api?
        response.code == 200
      end

      def invalid_config?
        response.code == 401
      end

      def api_down?
        (500..599).include?(response.code)
      end

      private
      attr_reader :response
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
