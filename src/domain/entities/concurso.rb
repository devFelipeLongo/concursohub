# frozen_string_literal: true

module Domain
  module Entities
    class Concurso
      attr_reader :instituicao, :estado, :vagas, :salario,
                  :cargos, :nivel, :prazo, :url

      def initialize(instituicao:, estado:, vagas:, salario:,
                     cargos:, nivel:, prazo:, url:)
        @instituicao = instituicao
        @estado      = estado
        @vagas       = vagas
        @salario     = salario
        @cargos      = cargos
        @nivel       = nivel
        @prazo       = prazo
        @url         = url

        freeze
      end
    end
  end
end
