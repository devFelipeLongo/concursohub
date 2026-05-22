# frozen_string_literal: true

require 'net/http'
require 'uri'
require_relative '../../application/ports/file_downloader'

module Infrastructure
  module Http
    class HttpFileDownloader < Application::Ports::FileDownloader
      USER_AGENT = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 ' \
                   '(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'

      def download(url, dest_path, redirect_limit: 5)
        raise 'Muitos redirecionamentos' if redirect_limit.zero?

        uri  = URI.parse(url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl      = (uri.scheme == 'https')
        http.open_timeout = 15
        http.read_timeout = 120

        request = Net::HTTP::Get.new(uri.request_uri)
        request['User-Agent'] = USER_AGENT

        http.start do |h|
          h.request(request) do |response|
            case response
            when Net::HTTPSuccess
              File.open(dest_path, 'wb') do |file|
                response.read_body { |chunk| file.write(chunk) }
              end
            when Net::HTTPRedirection
              new_url = response['location']
              new_url = URI.join(url, new_url).to_s unless new_url.start_with?('http')
              download(new_url, dest_path, redirect_limit: redirect_limit - 1)
            else
              raise "Erro HTTP: #{response.code} #{response.message}"
            end
          end
        end
      end
    end
  end
end
