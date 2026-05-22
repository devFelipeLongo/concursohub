# ConcursoHub

Gem Ruby para busca e extração de dados de concursos públicos brasileiros a partir do [PCI Concursos](https://pciconcursos.com.br).

Projetada com **arquitetura hexagonal (Ports & Adapters)**, a biblioteca mantém o núcleo de negócio completamente desacoplado de I/O — tornando-a ideal para uso em **APIs backend** (Rails, Sinatra, Grape, etc.) que precisam expor dados de concursos para um frontend consumir.

---

## Sumário

- [Instalação](#instalação)
- [Uso via CLI](#uso-via-cli)
- [Uso como gem em uma API backend](#uso-como-gem-em-uma-api-backend)
  - [ConcursoHub.search](#concursoscrapersearch)
  - [ConcursoHub.edital](#concursoscraperedital)
  - [ConcursoHub.provas](#concursoscraperprovas)
  - [ConcursoHub.download](#concursoscraperdownload)
  - [Exemplo completo em Rails](#exemplo-completo-em-rails)
- [Uso avançado (injeção de dependências)](#uso-avançado-injeção-de-dependências)
  - [Listar concursos](#listar-concursos)
  - [Ver edital completo](#ver-edital-completo)
  - [Baixar PDFs de um edital](#baixar-pdfs-de-um-edital)
  - [Baixar provas e gabaritos](#baixar-provas-e-gabaritos)
- [Arquitetura](#arquitetura)
- [Entidades de Domínio](#entidades-de-domínio)
- [Filtros disponíveis](#filtros-disponíveis)
- [Customizando adaptadores](#customizando-adaptadores)
- [Dependências](#dependências)

---

## Instalação

> **Nota:** A gem ainda não foi publicada no RubyGems. Para uso local ou como dependência privada, adicione ao seu `Gemfile`:

```ruby
gem 'concurso_hub', path: '/caminho/para/concurso_test'
# ou via git:
# gem 'concurso_hub', github: 'seu-usuario/concurso_hub'
```

Para instalar as dependências do projeto:

```bash
bundle install
```

---

## Uso via CLI

O projeto inclui uma interface de linha de comando para uso rápido e testes.

```bash
# Listar concursos abertos (padrão)
ruby main.rb

# Filtrar por estado
ruby main.rb --estado SP

# Filtrar por nível de escolaridade
ruby main.rb --nivel Superior

# Busca por texto (instituição ou cargo)
ruby main.rb --busca "analista"

# Limitar número de resultados
ruby main.rb --limite 10

# Filtrar por ano de inscrição
ruby main.rb --ano 2026

# Combinar filtros
ruby main.rb --estado RJ --nivel Medio --limite 20

# Listar concursos encerrados (requer --busca)
ruby main.rb --encerrados --busca "policia federal"

# Ver o edital completo de um concurso
ruby main.rb --ver https://pciconcursos.com.br/concurso/...

# Baixar os PDFs do edital de um concurso
ruby main.rb --baixar https://pciconcursos.com.br/concurso/...

# Baixar provas e gabaritos anteriores
ruby main.rb --baixar-provas https://pciconcursos.com.br/concurso/...

# Especificar pasta de destino para downloads
ruby main.rb --baixar https://... --dir ~/Downloads/concursos

# Ajuda
ruby main.rb --help
```

---

## Uso como gem em uma API backend

A maneira mais simples de usar a gem é através do módulo `ConcursoHub`, que expõe uma API de alto nível. Você só precisa adicionar o `require` e chamar os métodos — sem precisar saber nada sobre a arquitetura interna.

```ruby
require 'concurso_hub'
```

---

### ConcursoHub.search

Busca concursos com filtros opcionais. Retorna um hash com `concursos` (array) e `metadata`.

```ruby
# Busca simples — 1 requisição HTTP
resultado = ConcursoHub.search(estado: 'SP', nivel: 'Superior', limite: 10)

resultado[:concursos]
# => [
#   { instituicao: "TRF-3", estado: "SP", vagas: "50", salario: "R$ 8.529",
#     cargos: "Analista Judiciário", nivel: "Superior",
#     prazo: "10/06/2026", url: "https://pciconcursos.com.br/concurso/..." },
#   ...
# ]

resultado[:metadata]
# => { total_scraped: 120, modo: :abertos }
```

**Com dados do edital** — inclui PDFs e descrição para cada concurso (`+1 req por concurso`):

```ruby
resultado = ConcursoHub.search(estado: 'RJ', limite: 5, with_edital: true)

resultado[:concursos].first[:edital]
# => {
#   titulo:          "Edital nº 1/2026 — TRF-2",
#   descricao:       "...",
#   data_publicacao: "15/04/2026",
#   pdfs: [
#     { titulo: "Edital completo", url: "https://..." },
#     { titulo: "Retificação nº 1", url: "https://..." }
#   ],
#   provas_url: "https://pciconcursos.com.br/provas/...",  # nil se não houver
#   blocos: [...],
#   url: "https://pciconcursos.com.br/concurso/..."
# }
```

**Com provas e gabaritos** — inclui tudo acima mais a listagem de provas anteriores (`+N reqs por concurso` — use `limite`):

```ruby
resultado = ConcursoHub.search(estado: 'SP', limite: 2, with_provas: true)

resultado[:concursos].first[:provas]
# => [
#   {
#     cargo: "Analista Judiciário — Área Administrativa",
#     pdfs: [
#       { titulo: "Prova Objetiva — 2023", url: "https://..." },
#       { titulo: "Gabarito Preliminar — 2023", url: "https://..." }
#     ]
#   },
#   ...
# ]
```

**Parâmetros disponíveis:**

| Parâmetro     | Tipo              | Padrão     | Descrição                                               |
|---------------|-------------------|------------|---------------------------------------------------------|
| `estado`      | `String \| nil`   | `nil`      | UF (ex: `'SP'`, `'MG'`)                                |
| `nivel`       | `String \| nil`   | `nil`      | Escolaridade (ex: `'Superior'`, `'Médio'`)              |
| `busca`       | `String \| nil`   | `nil`      | Texto livre — obrigatório para `modo: :encerrados`      |
| `limite`      | `Integer \| nil`  | `nil`      | Máximo de resultados                                    |
| `ano`         | `String \| nil`   | `nil`      | Ano do prazo de inscrição (ex: `'2026'`)                |
| `modo`        | `Symbol`          | `:abertos` | `:abertos` ou `:encerrados`                             |
| `with_edital` | `Boolean`         | `false`    | Inclui edital com PDFs (+1 req/concurso)                |
| `with_provas` | `Boolean`         | `false`    | Inclui provas/gabaritos — implica `with_edital`         |

---

### ConcursoHub.edital

Retorna o edital completo de um concurso a partir da URL.

```ruby
edital = ConcursoHub.edital('https://pciconcursos.com.br/concurso/...')

edital[:titulo]          # => "Edital nº 1/2026"
edital[:data_publicacao] # => "15/04/2026"
edital[:descricao]       # => "..."
edital[:pdfs]            # => [{ titulo:, url: }, ...]
edital[:blocos]          # => [{ tipo: :secao|:paragrafo|:item, texto: }, ...]
edital[:url]             # => URL original
```

---

### ConcursoHub.provas

Retorna a listagem de provas e gabaritos anteriores. Recebe a mesma URL do concurso retornada pelo `search` — não precisa passar nenhuma URL intermediária.

```ruby
# url vem diretamente de search()
concurso_url = resultado[:concursos].first[:url]

provas = ConcursoHub.provas(concurso_url)

provas
# => [
#   {
#     cargo: "Analista Judiciário — Área Administrativa",
#     pdfs: [
#       { titulo: "Prova Objetiva — 2023", url: "https://..." },
#       { titulo: "Gabarito Preliminar — 2023", url: "https://..." }
#     ]
#   }
# ]
```

---

### ConcursoHub.download

Busca um PDF do PCI Concursos e retorna os **bytes brutos** (`String` binária) — sem salvar nada em disco. A gem é apenas a ponte; o backend decide o que fazer com os bytes.

```ruby
# url vem de edital[:pdfs].first[:url] ou provas[0][:pdfs].first[:url]
bytes = ConcursoHub.download(pdf_url)
```

**Casos de uso típicos em backends multi-usuário:**

```ruby
# 1. Stream direto para o cliente (Rails) — sem tocar no disco
bytes = ConcursoHub.download(params[:pdf_url])
send_data bytes, type: 'application/pdf', filename: 'documento.pdf', disposition: 'inline'

# 2. Salvar no S3 / object storage
bytes = ConcursoHub.download(pdf_url)
S3.put_object(bucket: 'meu-bucket', key: "provas/#{cargo}.pdf", body: bytes)

# 3. Encodar em Base64 para resposta JSON
require 'base64'
bytes = ConcursoHub.download(pdf_url)
render json: { filename: 'prova.pdf', content: Base64.strict_encode64(bytes) }
```

> **Nota:** Não utilize este método para salvar arquivos em disco em ambientes multi-usuário — prefira object storage (S3, GCS) ou stream direto ao cliente. O método `download` faz sentido em disco apenas na CLI (uso local).

---

### Exemplo completo em Rails

**`Gemfile`**
```ruby
gem 'concurso_hub', path: '../concurso_test'
# ou após publicar: gem 'concurso_hub', '~> 1.0'
```

**`app/controllers/concursos_controller.rb`**
```ruby
require 'concurso_hub'

class ConcursosController < ApplicationController
  # GET /concursos?estado=SP&nivel=Superior&limite=10
  def index
    resultado = ConcursoHub.search(
      estado: params[:estado],
      nivel:  params[:nivel],
      busca:  params[:busca],
      limite: params[:limite]&.to_i,
      ano:    params[:ano]
    )
    render json: resultado
  rescue => e
    render json: { error: e.message }, status: :bad_gateway
  end

  # GET /concursos/edital?url=https://pciconcursos.com.br/concurso/...
  def edital
    render json: ConcursoHub.edital(params[:url])
  rescue => e
    render json: { error: e.message }, status: :bad_gateway
  end

  # GET /concursos/provas?url=https://pciconcursos.com.br/concurso/...
  # (mesma url retornada pelo /concursos)
  def provas
    render json: ConcursoHub.provas(params[:url])
  rescue => e
    render json: { error: e.message }, status: :bad_gateway
  end

  # GET /concursos/download?url=https://pciconcursos.com.br/.../edital.pdf
  # Faz o stream do PDF direto ao cliente — sem salvar em disco
  def download
    bytes = ConcursoHub.download(params[:url])
    send_data bytes, type: 'application/pdf', disposition: 'inline'
  rescue => e
    render json: { error: e.message }, status: :bad_gateway
  end
end
```

**`config/routes.rb`**
```ruby
get '/concursos',          to: 'concursos#index'
get '/concursos/edital',   to: 'concursos#edital'
get '/concursos/provas',   to: 'concursos#provas'    # ?url= é a URL do concurso
get '/concursos/download', to: 'concursos#download'  # ?url= é a URL do PDF
```

---

## Uso avançado (injeção de dependências)

Se precisar de mais controle — mock para testes, presenter customizado, troca de repositório — você pode instanciar os use cases diretamente.

### Listar concursos

```ruby
require 'concurso_hub'  # ou os requires individuais de src/

# Presenter que coleta os dados em vez de imprimir
class MeuPresenter < Application::Ports::Presenter
  attr_reader :concursos, :metadata

  def show(concursos, metadata: {}) = (@concursos = concursos) && (@metadata = metadata)
  def error(msg)                    = raise msg
  def show_loading                  = nil
  def show_edital(_)                = nil
  def show_provas(_)                = nil
  def show_download_start(*)        = nil
  def show_download_done(_)         = nil
end

repository = Infrastructure::Repositories::PciConcursoRepository.new
presenter  = MeuPresenter.new

Application::UseCases::ListarConcursos.new(
  repository: repository,
  presenter:  presenter
).execute(
  Application::FiltrosConcurso.new(estado: 'SP', nivel: 'Superior', limite: 10, modo: :abertos)
)

presenter.concursos  # Array<Domain::Entities::Concurso>
presenter.metadata   # Hash
```

### Ver edital completo

```ruby
class EditalPresenter < Application::Ports::Presenter
  attr_reader :edital

  def show_edital(edital) = @edital = edital
  def error(msg)          = raise msg
  def show(*)             = nil
  def show_loading        = nil
  def show_provas(_)      = nil
  def show_download_start(*) = nil
  def show_download_done(_)  = nil
end

presenter = EditalPresenter.new
Application::UseCases::VerEdital.new(
  repository: Infrastructure::Repositories::PciConcursoRepository.new,
  presenter:  presenter
).execute(Application::VerEditalRequest.new(url: 'https://pciconcursos.com.br/concurso/...'))

presenter.edital.titulo    # => String
presenter.edital.pdfs      # => [{ titulo:, url: }]
presenter.edital.provas_url # => String | nil
```

### Baixar PDFs de um edital

```ruby
require 'application/use_cases/baixar_edital'
require 'application/baixar_edital_request'
require 'infrastructure/http/http_file_downloader'

Application::UseCases::BaixarEdital.new(
  repository: Infrastructure::Repositories::PciConcursoRepository.new,
  downloader: Infrastructure::Http::HttpFileDownloader.new,
  presenter:  presenter  # qualquer presenter com show_download_start/done
).execute(
  Application::BaixarEditalRequest.new(
    url:      'https://pciconcursos.com.br/concurso/...',
    dest_dir: '/tmp/editais'
  )
)
# PDFs salvos em dest_dir
```

### Baixar provas e gabaritos

```ruby
require 'application/use_cases/baixar_provas'
require 'application/baixar_provas_request'

Application::UseCases::BaixarProvas.new(
  repository: Infrastructure::Repositories::PciConcursoRepository.new,
  downloader: Infrastructure::Http::HttpFileDownloader.new,
  presenter:  presenter
).execute(
  Application::BaixarProvasRequest.new(
    url:      'https://pciconcursos.com.br/concurso/...',  # mesma URL do concurso
    dest_dir: '/tmp/provas'
  )
)
# PDFs salvos em dest_dir organizados por cargo
```

---

## Arquitetura

O projeto segue a **arquitetura hexagonal (Ports & Adapters)** com separação estrita de camadas:

```
┌─────────────────────────────────────────────────────┐
│  Apresentação (Adaptadores de entrada)              │
│  CLI: CliOptionsParser → CliController              │
│  API: Controller Rails/Sinatra/etc. (você implementa)│
│  TerminalPresenter  ←→  JsonPresenter (custom)      │
└──────────────────────┬──────────────────────────────┘
                       │ Request objects
┌──────────────────────▼──────────────────────────────┐
│  Aplicação (Núcleo — sem dependências de framework) │
│  Use Cases: ListarConcursos, VerEdital,             │
│             BaixarEdital, BaixarProvas              │
│  Ports (interfaces): ConcursoRepository,            │
│                      FileDownloader, Presenter      │
│  Value Objects: FiltrosConcurso, *Request           │
└──────────────────────┬──────────────────────────────┘
                       │ Entidades de domínio
┌──────────────────────▼──────────────────────────────┐
│  Domínio (Puro, sem dependências externas)          │
│  Entities: Concurso, Edital (imutáveis/frozen)      │
└──────────────────────┬──────────────────────────────┘
                       │ implementa ports
┌──────────────────────▼──────────────────────────────┐
│  Infraestrutura (Adaptadores de saída)              │
│  PciConcursoRepository (implementa ConcursoRepository)│
│  HttpClient, HttpFileDownloader                     │
│  PciHtmlParser (Nokogiri)                           │
└─────────────────────────────────────────────────────┘
```

**Princípio central:** os use cases dependem apenas das interfaces (ports) — nunca de infraestrutura diretamente. Isso permite trocar a fonte de dados (outro site, banco de dados, mock) sem alterar o núcleo.

---

## Entidades de Domínio

### `Domain::Entities::Concurso`

| Atributo     | Tipo     | Descrição                                  |
|--------------|----------|--------------------------------------------|
| `instituicao`| `String` | Nome do órgão/instituição                  |
| `estado`     | `String` | UF (ex: `SP`, `RJ`)                        |
| `vagas`      | `String` | Número de vagas                            |
| `salario`    | `String` | Faixa salarial                             |
| `cargos`     | `String` | Cargos disponíveis                         |
| `nivel`      | `String` | Nível de escolaridade exigido              |
| `prazo`      | `String` | Data-limite de inscrição                   |
| `url`        | `String` | URL do edital no PCI Concursos             |

### `Domain::Entities::Edital`

| Atributo          | Tipo             | Descrição                                            |
|-------------------|------------------|------------------------------------------------------|
| `titulo`          | `String`         | Título do edital                                     |
| `descricao`       | `String`         | Descrição resumida                                   |
| `data_publicacao` | `String`         | Data de publicação                                   |
| `blocos`          | `Array<Hash>`    | Conteúdo estruturado: `{ tipo:, texto: }`            |
| `pdfs`            | `Array<Hash>`    | Lista de PDFs: `{ titulo:, url: }`                   |
| `provas_url`      | `String \| nil`  | URL da página de provas anteriores (se disponível)   |
| `url`             | `String`         | URL canônica do edital                               |

Os tipos de bloco em `blocos` são: `:secao`, `:paragrafo`, `:item`.

---

## Filtros disponíveis

`Application::FiltrosConcurso` é um `Struct` com os seguintes campos:

| Campo    | Tipo              | Descrição                                        | Exemplo         |
|----------|-------------------|--------------------------------------------------|-----------------|
| `estado` | `String \| nil`   | Filtrar por UF                                   | `'SP'`, `'MG'`  |
| `nivel`  | `String \| nil`   | Nível de escolaridade                            | `'Superior'`    |
| `busca`  | `String \| nil`   | Busca textual (obrigatório para `:encerrados`)   | `'analista'`    |
| `limite` | `Integer \| nil`  | Máximo de resultados retornados                  | `10`            |
| `modo`   | `Symbol`          | `:abertos` (padrão) ou `:encerrados`             | `:abertos`      |
| `ano`    | `String \| nil`   | Ano do prazo de inscrição                        | `'2026'`        |

---

## Customizando adaptadores

A arquitetura foi pensada para facilitar extensão. Você pode substituir qualquer adaptador sem tocar no núcleo.

### Repositório mock para testes

```ruby
require 'application/ports/concurso_repository'
require 'domain/entities/concurso'

class MockConcursoRepository < Application::Ports::ConcursoRepository
  def fetch_abertos
    concursos = [
      Domain::Entities::Concurso.new(
        instituicao: 'TRF-1',
        estado:      'DF',
        vagas:       '50',
        salario:     'R$ 8.000',
        cargos:      'Analista Judiciário',
        nivel:       'Superior',
        prazo:       '30/06/2026',
        url:         'https://example.com/concurso'
      )
    ]
    [concursos, { total_scraped: 1, modo: :abertos }]
  end

  # Implementar outros métodos conforme necessário para os testes...
end

# Injetar na ConcursoHub ou diretamente nos use cases
resultado = ConcursoHub.search(estado: 'DF')
# Para usar o mock, injete via uso direto dos use cases (seção anterior)
```

---

## Dependências

| Gem        | Versão   | Uso                          |
|------------|----------|------------------------------|
| `nokogiri` | `~> 1.16`| Parsing de HTML              |

Todo o restante utiliza apenas a biblioteca padrão do Ruby: `net/http`, `uri`, `optparse`.

**Versão mínima de Ruby:** 3.1 (usa pattern matching e hash shorthand syntax).

---

## Contribuindo

Pull requests são bem-vindos. Ao adicionar suporte a uma nova fonte de dados (além do PCI Concursos), implemente a interface `Application::Ports::ConcursoRepository` e injete o novo adaptador — o núcleo não precisa ser alterado.
