# frozen_string_literal: true

module Application
  FiltrosConcurso = Struct.new(
    :estado,
    :nivel,
    :busca,
    :limite,
    :modo,
    :ano,
    keyword_init: true
  ) do
    def abertos?    = modo != :encerrados
    def encerrados? = modo == :encerrados
  end
end
