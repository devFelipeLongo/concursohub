# frozen_string_literal: true

require_relative 'lib/concurso_hub/version'

Gem::Specification.new do |s|
  s.name        = 'concurso_hub'
  s.version     = ConcursoHub::VERSION
  s.summary     = 'Busca e extração de dados de concursos públicos brasileiros'
  s.description = 'Gem Ruby para buscar concursos públicos brasileiros a partir do PCI Concursos. ' \
                  'Retorna listagens, editais e provas em estruturas de dados prontas para APIs backend.'
  s.authors     = ['Felipe Longo']
  s.email       = 'felipelongo321@gmail.com'
  s.homepage    = 'https://github.com/devFelipeLongo/concursohub'
  s.license     = 'MIT'

  s.required_ruby_version = '>= 3.1'

  s.files = Dir[
    'lib/**/*.rb',
    'src/**/*.rb',
    'README.md',
    'LICENSE.txt'
  ]

  s.require_paths = ['lib']

  s.add_dependency 'nokogiri', '~> 1.16'
end
