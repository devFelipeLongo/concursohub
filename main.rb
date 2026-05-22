#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift(File.join(__dir__, 'src'))

require 'application/use_cases/listar_concursos'
require 'application/use_cases/ver_edital'
require 'application/use_cases/baixar_edital'
require 'application/use_cases/baixar_provas'
require 'infrastructure/repositories/pci_concurso_repository'
require 'infrastructure/http/http_file_downloader'
require 'presentation/formatters/terminal_presenter'
require 'presentation/cli/cli_controller'


presenter  = Presentation::Formatters::TerminalPresenter.new
repository = Infrastructure::Repositories::PciConcursoRepository.new
downloader = Infrastructure::Http::HttpFileDownloader.new
use_case   = Application::UseCases::ListarConcursos.new(
  repository: repository,
  presenter:  presenter
)
ver_edital = Application::UseCases::VerEdital.new(
  repository: repository,
  presenter:  presenter
)
baixar_edital = Application::UseCases::BaixarEdital.new(
  repository: repository,
  downloader: downloader,
  presenter:  presenter
)
baixar_provas = Application::UseCases::BaixarProvas.new(
  repository: repository,
  downloader: downloader,
  presenter:  presenter
)
controller = Presentation::Cli::CliController.new(
  use_case:      use_case,
  ver_edital:    ver_edital,
  baixar_edital: baixar_edital,
  baixar_provas: baixar_provas,
  presenter:     presenter,
  repository:    repository
)

presenter.show_loading

begin
  controller.run(ARGV)
rescue SocketError, Errno::ECONNREFUSED => e
  presenter.error("Erro de conexão: #{e.message}")
  exit 1
rescue RuntimeError => e
  presenter.error("Erro: #{e.message}")
  exit 1
end
