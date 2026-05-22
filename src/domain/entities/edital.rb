# frozen_string_literal: true

module Domain
  module Entities
    class Edital
      attr_reader :titulo, :descricao, :data_publicacao, :blocos, :pdfs, :provas_url, :url

      def initialize(titulo:, descricao:, data_publicacao:, blocos:, pdfs: [], provas_url: nil, url:)
        @titulo          = titulo
        @descricao       = descricao
        @data_publicacao = data_publicacao
        @blocos          = blocos.freeze
        @pdfs            = pdfs.freeze
        @provas_url      = provas_url
        @url             = url

        freeze
      end
    end
  end
end
