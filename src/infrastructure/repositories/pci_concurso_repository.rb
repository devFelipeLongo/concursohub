# frozen_string_literal: true

require 'uri'
require_relative '../../application/ports/concurso_repository'
require_relative '../http/http_client'
require_relative '../parsers/pci_html_parser'

module Infrastructure
  module Repositories
    class PciConcursoRepository < Application::Ports::ConcursoRepository
      ABERTOS_URL    = 'https://www.pciconcursos.com.br/concursos/'
      ENCERRADOS_URL = 'https://www.pciconcursos.com.br/pesquisa/'

      def initialize(
        http_client: Http::HttpClient.new,
        parser:      Parsers::PciHtmlParser.new
      )
        @http_client = http_client
        @parser      = parser
      end

      def fetch_abertos
        html = @http_client.get(ABERTOS_URL)
        @parser.parse_abertos(html)
      end

      def fetch_encerrados(busca)
        url  = "#{ENCERRADOS_URL}?p=#{URI.encode_www_form_component(busca)}&tipopesquisa=1"
        html = @http_client.get(url)
        @parser.parse_encerrados(html)
      end

      def fetch_edital(url)
        html = @http_client.get(url)
        @parser.parse_edital(html, url)
      end

      def fetch_provas_listing(provas_url)
        html = @http_client.get(provas_url)
        @parser.parse_provas_listing(html)
      end

      def fetch_prova_pdfs(download_url)
        html = @http_client.get(download_url)
        @parser.parse_prova_download_page(html)
      end
    end
  end
end
