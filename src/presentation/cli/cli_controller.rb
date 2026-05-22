# frozen_string_literal: true

require_relative 'cli_options_parser'
require_relative '../../application/ver_edital_request'
require_relative '../../application/baixar_edital_request'
require_relative '../../application/baixar_provas_request'

module Presentation
  module Cli
    class CliController
      def initialize(use_case:, ver_edital:, baixar_edital:, baixar_provas:, presenter:, repository:, options_parser: CliOptionsParser.new)
        @use_case       = use_case
        @ver_edital     = ver_edital
        @baixar_edital  = baixar_edital
        @baixar_provas  = baixar_provas
        @presenter      = presenter
        @repository     = repository
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
          interactive_menu
        end
      end

      private

      def interactive_menu
        concursos = @presenter.last_concursos
        return if concursos.nil? || concursos.empty?

        print "\nSelecione um concurso (1-#{concursos.size}) ou Enter para sair: "
        input = $stdin.gets&.chomp
        return if input.nil? || input.empty?

        index = input.to_i - 1
        return unless index.between?(0, concursos.size - 1)

        concurso = concursos[index]

        puts "\n  \e[1m\e[97m#{concurso.instituicao}\e[0m  —  #{concurso.estado}"
        puts
        puts "  [1] Ver edital completo"
        puts "  [2] Baixar PDFs do edital"
        puts "  [3] Baixar provas e gabaritos"
        print "\n  Opção (Enter para cancelar): "

        case $stdin.gets&.chomp
        when '1'
          @ver_edital.execute(Application::VerEditalRequest.new(url: concurso.url))
        when '2'
          @baixar_edital.execute(Application::BaixarEditalRequest.new(url: concurso.url, dest_dir: nil))
        when '3'
          edital = @repository.fetch_edital(concurso.url)
          unless edital.provas_url
            puts "\n  \e[31mNenhuma prova disponível para este concurso.\e[0m"
            return
          end
          @baixar_provas.execute(Application::BaixarProvasRequest.new(url: edital.provas_url, dest_dir: nil))
        end
      end
    end
  end
end

