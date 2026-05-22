# frozen_string_literal: true

require_relative 'cli_options_parser'
require_relative '../../application/ver_edital_request'
require_relative '../../application/baixar_edital_request'
require_relative '../../application/baixar_provas_request'

module Presentation
  module Cli
    class CliController
      def initialize(use_case:, ver_edital:, baixar_edital:, baixar_provas:, options_parser: CliOptionsParser.new)
        @use_case       = use_case
        @ver_edital     = ver_edital
        @baixar_edital  = baixar_edital
        @baixar_provas  = baixar_provas
        @options_parser = options_parser
      end

      def run(args)
        request = @options_parser.parse(args)

        case request
        when Application::BaixarProvasRequest
          @baixar_provas.execute(request)
        when Application::BaixarEditalRequest
          @baixar_edital.execute(request)
        when Application::VerEditalRequest
          @ver_edital.execute(request)
        else
          @use_case.execute(request)
        end
      end
    end
  end
end
