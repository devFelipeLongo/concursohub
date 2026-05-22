# frozen_string_literal: true

require_relative '../ver_edital_request'
require_relative '../ports/concurso_repository'
require_relative '../ports/presenter'

module Application
  module UseCases
    class ListarProvas
      def initialize(repository:, presenter:)
        @repository = repository
        @presenter  = presenter
      end

      def execute(request)
        listing = @repository.fetch_provas_listing(request.url)

        if listing.empty?
          @presenter.error("Nenhuma prova encontrada em: #{request.url}")
          return
        end

        resultado = listing.map do |prova|
          pdfs = @repository.fetch_prova_pdfs(prova[:download_url])
          { cargo: prova[:cargo], pdfs: pdfs }
        end

        @presenter.show_provas(resultado)
      end
    end
  end
end
