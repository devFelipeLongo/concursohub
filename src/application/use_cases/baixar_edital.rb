# frozen_string_literal: true

require 'uri'
require_relative '../baixar_edital_request'
require_relative '../ports/concurso_repository'
require_relative '../ports/file_downloader'
require_relative '../ports/presenter'

module Application
  module UseCases
    class BaixarEdital
      def initialize(repository:, downloader:, presenter:)
        @repository = repository
        @downloader = downloader
        @presenter  = presenter
      end

      def execute(request)
        edital = @repository.fetch_edital(request.url)

        if edital.pdfs.empty?
          @presenter.error("Nenhum PDF encontrado para este edital.")
          return
        end

        dest_dir = request.dest_dir || File.join(Dir.pwd, 'editais')
        Dir.mkdir(dest_dir) unless Dir.exist?(dest_dir)

        downloaded = []
        edital.pdfs.each_with_index do |pdf, index|
          filename  = File.basename(URI.parse(pdf[:url]).path)
          dest_path = File.join(dest_dir, filename)

          @presenter.show_download_start(pdf[:titulo], index + 1, edital.pdfs.size)
          @downloader.download(pdf[:url], dest_path)
          downloaded << dest_path
        end

        @presenter.show_download_done(downloaded)
      end
    end
  end
end
