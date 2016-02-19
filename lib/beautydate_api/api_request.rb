#encoding: UTF-8

require 'rest_client'
require "base64"
require "json"

module BeautydateApi
  class APIRequest
    class << self
      def consumer
        @consumer ||= BeautydateApi::APIConsumer.new.authenticate(BeautydateApi.api_key)
      rescue BeautydateApi::ObjectNotFound => e
        raise BeautydateApi::AuthenticationException, "Não foi possível autenticar o Consumer, verifique o BEAUTYDATE_TOKEN"
      end

      def request(method, url, data = {})
        handle_response send_request(method, url, data)
      end

      protected
      def send_request(method, url, data)
        RestClient::Request.execute build_request(method, url, data)
      rescue RestClient::ResourceNotFound
        raise ObjectNotFound
      rescue RestClient::UnprocessableEntity => e
        raise RequestWithErrors.new JSON.parse(e.response)
      rescue RestClient::BadRequest => e
        raise RequestWithErrors.new JSON.parse(e.response)
      end

      def handle_response(response)
        JSON.parse(response.body)
      rescue JSON::ParserError
        raise RequestFailed
      end

      def build_request(method, url, data)
        { 
          method: method,
          url: url,
          headers: headers,
          payload: {
            data: data.to_json
          },
          timeout: 30
        }
      end

      def headers
        {
          user_agent: "Beauty Date Ruby Client #{BeautydateApi::VERSION}",
          content_type: 'application/vnd.api+json',
          authorization: self.consumer.bearer
        }
      end
    end
  end
end
