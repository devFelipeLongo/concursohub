# frozen_string_literal: true

require_relative '../ver_edital_request'
require_relative '../ports/concurso_repository'
require_relative '../ports/presenter'

module Application
  module UseCases
    class VerEdital
      def initialize(repository:, presenter:)
        @repository = repository
        @presenter  = presenter
      end

      def execute(request)
        edital = @repository.fetch_edital(request.url)
        @presenter.show_edital(edital)
      end
    end
  end
end
