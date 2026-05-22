# frozen_string_literal: true

require 'optparse'
require_relative '../../application/filtros_concurso'
require_relative '../../application/ver_edital_request'
require_relative '../../application/baixar_edital_request'
require_relative '../../application/baixar_provas_request'

module Presentation
  module Cli
    class CliOptionsParser
      ESTADOS_VALIDOS = %w[
        NACIONAL AC AL AM AP BA CE DF ES GO MA MG MS MT PA PB PE PI PR
        RJ RN RO RR RS SC SE SP TO
      ].freeze

      def parse(args)
        options    = {}
        ver_url    = nil
        baixar_url = nil
        baixar_provas_url = nil
        dest_dir   = nil

        parser = OptionParser.new do |opts|
          opts.banner = build_banner
          opts.separator 'Opções:'

          opts.on('--ver URL',
                  'Exibir o edital completo de um concurso pela URL') do |v|
            ver_url = v
          end

          opts.on('--baixar URL',
                  'Baixar os PDFs do edital de um concurso pela URL') do |v|
            baixar_url = v
          end

          opts.on('--baixar-provas URL',
                  'Baixar provas/gabaritos de uma página de provas do pciconcursos') do |v|
            baixar_provas_url = v
          end

          opts.on('--dir PASTA',
                  'Pasta de destino para --baixar (padrão: ./editais/)') do |v|
            dest_dir = v
          end

          opts.on('--estado ESTADO',
                  "Filtrar por estado/UF (#{ESTADOS_VALIDOS.join(', ')})") do |v|
            options[:estado] = v.upcase
          end

          opts.on('--nivel NIVEL',
                  'Filtrar por escolaridade (ex: Superior, Médio, Técnico)') do |v|
            options[:nivel] = v
          end

          opts.on('--busca TEXTO',
                  'Buscar texto no nome da instituição ou cargo') do |v|
            options[:busca] = v
          end

          opts.on('--limite N', Integer,
                  'Limitar o número de resultados exibidos') do |v|
            options[:limite] = v
          end

          opts.on('--ano ANO', Integer,
                  'Filtrar pelo ano no prazo de inscrição (ex: 2025, 2026)') do |v|
            options[:ano] = v
          end

          opts.on('--abertos',
                  'Mostrar concursos com inscrições abertas (padrão)') do
            options[:modo] = :abertos
          end

          opts.on('--encerrados',
                  'Mostrar concursos encerrados (requer --busca)') do
            options[:modo] = :encerrados
          end

          opts.on('-h', '--help', 'Exibir esta ajuda') do
            puts opts
            exit
          end
        end

        parser.parse!(args)
        return Application::BaixarProvasRequest.new(url: baixar_provas_url, dest_dir: dest_dir) if baixar_provas_url
        return Application::BaixarEditalRequest.new(url: baixar_url, dest_dir: dest_dir) if baixar_url
        return Application::VerEditalRequest.new(url: ver_url) if ver_url

        Application::FiltrosConcurso.new(**options)
      end

      private

      def build_banner
        <<~BANNER

          Uso:
            ruby main.rb [opções]

          Exemplos:
            ruby main.rb                               # todos os abertos
            ruby main.rb --estado SP                   # apenas SP
            ruby main.rb --nivel Superior              # nível superior
            ruby main.rb --busca analista              # busca por texto
            ruby main.rb --estado MG --limite 10       # 10 primeiros de MG
            ruby main.rb --encerrados --busca policia  # encerrados sobre polícia
            ruby main.rb --ver URL                     # edital completo de um concurso
            ruby main.rb --baixar URL                  # baixar PDFs do edital
            ruby main.rb --baixar URL --dir ~/Downloads
            ruby main.rb --baixar-provas URL            # baixar provas/gabaritos anteriores

        BANNER
      end
    end
  end
end
