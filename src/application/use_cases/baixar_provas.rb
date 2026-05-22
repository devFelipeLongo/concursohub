# frozen_string_literal: true

require 'uri'
require_relative '../baixar_provas_request'
require_relative '../ports/concurso_repository'
require_relative '../ports/file_downloader'
require_relative '../ports/presenter'

module Application
  module UseCases
    class BaixarProvas
      def initialize(repository:, downloader:, presenter:)
        @repository = repository
        @downloader = downloader
        @presenter  = presenter
      end

      def execute(request)
        provas = @repository.fetch_provas_listing(request.url)

        if provas.empty?
          @presenter.error("Nenhuma prova encontrada em: #{request.url}")
          return
        end

        todos_pdfs = []
        provas.each_with_index do |prova, i|
          @presenter.show_download_start(
            "Buscando provas de: #{prova[:cargo]}", i + 1, provas.size
          )
          pdfs = @repository.fetch_prova_pdfs(prova[:download_url])
          pdfs.each { |pdf| todos_pdfs << { cargo: prova[:cargo], **pdf } }
        end

        if todos_pdfs.empty?
          @presenter.error("Nenhum PDF de prova encontrado.")
          return
        end

        dest_dir = request.dest_dir || File.join(Dir.pwd, 'editais')
        Dir.mkdir(dest_dir) unless Dir.exist?(dest_dir)

        downloaded = []
        todos_pdfs.each_with_index do |pdf, i|
          filename  = File.basename(URI.parse(pdf[:url]).path)
          dest_path = File.join(dest_dir, filename)

          @presenter.show_download_start(
            "#{pdf[:cargo]} — #{pdf[:titulo]}", i + 1, todos_pdfs.size
          )
          @downloader.download(pdf[:url], dest_path)
          downloaded << dest_path
        end

        @presenter.show_download_done(downloaded)
      end
    end
  end
end
