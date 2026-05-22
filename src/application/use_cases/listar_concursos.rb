# frozen_string_literal: true

require_relative '../filtros_concurso'
require_relative '../ports/concurso_repository'
require_relative '../ports/presenter'

module Application
  module UseCases
    class ListarConcursos
      def initialize(repository:, presenter:)
        @repository = repository
        @presenter  = presenter
      end

      def execute(filtros = FiltrosConcurso.new)
        if filtros.encerrados?
          executar_encerrados(filtros)
        else
          executar_abertos(filtros)
        end
      end

      private

      def executar_abertos(filtros)
        concursos, metadata = @repository.fetch_abertos
        metadata[:total_scraped] = concursos.size
        metadata[:modo]          = :abertos

        concursos = aplicar_filtros(concursos, filtros, incluir_busca: true)
        concursos = concursos.first(filtros.limite) if filtros.limite
        @presenter.show(concursos, metadata: metadata)
      end

      def executar_encerrados(filtros)
        unless filtros.busca
          @presenter.error("--encerrados requer --busca TEXTO (ex: ruby main.rb --encerrados --busca policia)")
          return
        end

        concursos, metadata = @repository.fetch_encerrados(filtros.busca)
        metadata[:total_scraped] = concursos.size
        metadata[:modo]          = :encerrados
        metadata[:busca]         = filtros.busca

        concursos = aplicar_filtros(concursos, filtros, incluir_busca: false)
        concursos = concursos.first(filtros.limite) if filtros.limite
        @presenter.show(concursos, metadata: metadata)
      end

      def aplicar_filtros(concursos, filtros, incluir_busca: true)
        concursos = filtrar_por_estado(concursos, filtros.estado)
        concursos = filtrar_por_nivel(concursos, filtros.nivel)
        concursos = filtrar_por_busca(concursos, filtros.busca) if incluir_busca
        concursos = filtrar_por_ano(concursos, filtros.ano)
        concursos
      end

      def filtrar_por_estado(concursos, estado)
        return concursos unless estado

        concursos.select { |c| c.estado == estado }
      end

      def filtrar_por_nivel(concursos, nivel)
        return concursos unless nivel

        term = nivel.downcase
        concursos.select { |c| c.nivel.downcase.include?(term) }
      end

      def filtrar_por_busca(concursos, busca)
        return concursos unless busca

        term = busca.downcase
        concursos.select do |c|
          c.instituicao.downcase.include?(term) ||
            c.cargos.downcase.include?(term)
        end
      end

      def filtrar_por_ano(concursos, ano)
        return concursos unless ano

        concursos.select { |c| c.prazo.include?(ano.to_s) }
      end
    end
  end
end
