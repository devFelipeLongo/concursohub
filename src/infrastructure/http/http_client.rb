# frozen_string_literal: true

require 'net/http'
require 'uri'

module Infrastructure
  module Http
    class HttpClient
      USER_AGENT = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 ' \
                   '(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'

      def get(url, redirect_limit: 5)
        raise 'Muitos redirecionamentos' if redirect_limit.zero?

        uri      = URI.parse(url)
        http     = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl      = (uri.scheme == 'https')
        http.open_timeout = 15
        http.read_timeout = 30

        request = Net::HTTP::Get.new(uri.request_uri)
        request['User-Agent']      = USER_AGENT
        request['Accept']          = 'text/html,application/xhtml+xml'
        request['Accept-Language'] = 'pt-BR,pt;q=0.9'

        response = http.request(request)

        case response
        when Net::HTTPSuccess
          body = response.body
          body.force_encoding('UTF-8')
          body
        when Net::HTTPRedirection
          get(response['location'], redirect_limit: redirect_limit - 1)
        else
          raise "Erro HTTP: #{response.code} #{response.message}"
        end
      end
    end
  end
end
