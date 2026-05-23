# frozen_string_literal: true

require_relative 'concurso_hub/version'

$LOAD_PATH.unshift(File.join(__dir__, '..', 'src'))

require 'application/filtros_concurso'
require 'application/ver_edital_request'
require 'application/ports/presenter'
require 'application/use_cases/listar_concursos'
require 'application/use_cases/ver_edital'
require 'application/use_cases/listar_provas'
require 'infrastructure/repositories/pci_concurso_repository'
require 'infrastructure/http/http_file_downloader'

module ConcursoHub
  def self.search(
    estado: nil,
    nivel: nil,
    busca: nil,
    limite: nil,
    ano: nil,
    modo: :abertos,
    with_edital: false,
    with_provas: false
  )
    repository = build_repository
    presenter  = SilentPresenter.new

    Application::UseCases::ListarConcursos.new(
      repository: repository,
      presenter:  presenter
    ).execute(
      Application::FiltrosConcurso.new(
        estado: estado, nivel: nivel, busca: busca,
        limite: limite, ano: ano, modo: modo
      )
    )

    raise presenter.erro if presenter.erro

    concursos = presenter.concursos.map { |c| serialize_concurso(c) }

    if with_edital || with_provas
      concursos.each do |c|
        edital_data = fetch_edital_hash(c[:url], repository)
        c[:edital]  = edital_data

        if with_provas && edital_data[:provas_url]
          c[:provas] = fetch_provas_array(edital_data[:provas_url], repository)
        else
          c[:provas] = [] if with_provas
        end
      end
    end

    { concursos: concursos, metadata: presenter.metadata }
  end

  def self.edital(url)
    fetch_edital_hash(url, build_repository)
  end

  def self.download(url)
    Infrastructure::Http::HttpFileDownloader.new.fetch_bytes(url)
  end

  def self.provas(url)
    repository = build_repository
    edital     = fetch_edital_hash(url, repository)
    return [] unless edital[:provas_url]

    fetch_provas_array(edital[:provas_url], repository)
  end

  private_class_method def self.build_repository
    Infrastructure::Repositories::PciConcursoRepository.new
  end

  private_class_method def self.fetch_edital_hash(url, repository)
    presenter = SilentPresenter.new
    Application::UseCases::VerEdital.new(
      repository: repository,
      presenter:  presenter
    ).execute(Application::VerEditalRequest.new(url: url))

    raise presenter.erro if presenter.erro

    serialize_edital(presenter.edital)
  end

  private_class_method def self.fetch_provas_array(url, repository)
    presenter = SilentPresenter.new
    Application::UseCases::ListarProvas.new(
      repository: repository,
      presenter:  presenter
    ).execute(Application::VerEditalRequest.new(url: url))

    return [] if presenter.erro

    presenter.provas
  end

  private_class_method def self.serialize_concurso(c)
    {
      instituicao: c.instituicao,
      estado:      c.estado,
      vagas:       c.vagas,
      salario:     c.salario,
      cargos:      c.cargos,
      nivel:       c.nivel,
      prazo:       c.prazo,
      url:         c.url
    }
  end

  private_class_method def self.serialize_edital(e)
    {
      titulo:          e.titulo,
      descricao:       e.descricao,
      data_publicacao: e.data_publicacao,
      pdfs:            e.pdfs,
      provas_url:      e.provas_url,
      blocos:          e.blocos,
      url:             e.url
    }
  end

  class SilentPresenter < Application::Ports::Presenter
    attr_reader :concursos, :edital, :provas, :metadata, :erro

    def show(concursos, metadata: {})
      @concursos = concursos
      @metadata  = metadata
    end

    def show_edital(edital)  = @edital = edital
    def show_provas(provas)  = @provas = provas
    def error(message)       = @erro   = message

    def show_loading           = nil
    def show_download_start(*) = nil
    def show_download_done(_)  = nil
  end
  private_constant :SilentPresenter
end

