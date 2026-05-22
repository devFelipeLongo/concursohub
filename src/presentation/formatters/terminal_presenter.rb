# frozen_string_literal: true

require_relative '../../application/ports/presenter'

module Presentation
  module Formatters
    class TerminalPresenter < Application::Ports::Presenter
      RESET  = "\e[0m"
      BOLD   = "\e[1m"
      DIM    = "\e[2m"
      RED    = "\e[31m"
      GREEN  = "\e[32m"
      YELLOW = "\e[33m"
      BLUE   = "\e[34m"
      CYAN   = "\e[36m"
      WHITE  = "\e[97m"

      attr_reader :last_concursos

      def show_loading
        puts "#{CYAN}Conectando ao pciconcursos.com.br…#{RESET}"
      end

      def show(concursos, metadata: {})
        @last_concursos = concursos
        if concursos.empty?
          puts "\n#{RED}Nenhum concurso encontrado com os filtros informados.#{RESET}\n"
          return
        end

        render_header(metadata)
        render_concursos(concursos)
        render_footer(concursos.size)
      end

      def error(message)
        warn "#{RED}#{message}#{RESET}"
      end

      def show_edital(edital)
        puts
        puts "#{BOLD}#{CYAN}╔══════════════════════════════════════════════════════════╗#{RESET}"
        puts "#{BOLD}#{CYAN}║  EDITAL COMPLETO                                         ║#{RESET}"
        puts "#{BOLD}#{CYAN}╚══════════════════════════════════════════════════════════╝#{RESET}"
        puts
        puts "#{BOLD}#{WHITE}#{edital.titulo}#{RESET}"
        puts
        puts "#{DIM}#{edital.descricao}#{RESET}"                                    unless edital.descricao.empty?
        puts "#{DIM}Publicado em: #{edital.data_publicacao}#{RESET}"                unless edital.data_publicacao.empty?
        puts "#{DIM}Fonte: #{edital.url}#{RESET}"
        puts
        puts "#{DIM}#{'─' * 70}#{RESET}"
        puts

        edital.blocos.each do |bloco|
          case bloco[:tipo]
          when :secao
            puts "\n#{BOLD}#{YELLOW}#{bloco[:texto]}#{RESET}\n"
          when :paragrafo
            puts wrap_text(bloco[:texto])
            puts
          when :item
            puts "  #{CYAN}•#{RESET} #{wrap_text(bloco[:texto], indent: 4)}"
          end
        end

        unless edital.pdfs.empty?
          puts
          puts "#{BOLD}#{YELLOW}PDFs disponíveis:#{RESET}"
          edital.pdfs.each_with_index do |pdf, i|
            puts "  #{CYAN}[#{i + 1}]#{RESET} #{pdf[:titulo]}"
            puts "      #{DIM}#{pdf[:url]}#{RESET}"
          end
          puts
          puts "#{DIM}Use --baixar URL para fazer download dos PDFs.#{RESET}"
        end

        if edital.provas_url
          puts
          puts "#{BOLD}#{YELLOW}Provas anteriores disponíveis:#{RESET}"
          puts "  #{DIM}#{edital.provas_url}#{RESET}"
          puts "#{DIM}Use --baixar-provas #{edital.provas_url} para baixar todas as provas.#{RESET}"
        end
      end

      def show_provas(provas)
        if provas.empty?
          puts "\n#{RED}Nenhuma prova encontrada.#{RESET}\n"
          return
        end

        puts
        puts "#{BOLD}#{CYAN}Provas e gabaritos disponíveis:#{RESET}"
        puts
        provas.each do |prova|
          puts "#{BOLD}#{YELLOW}#{prova[:cargo]}#{RESET}"
          prova[:pdfs].each_with_index do |pdf, i|
            puts "  #{CYAN}[#{i + 1}]#{RESET} #{pdf[:titulo]}"
            puts "      #{DIM}#{pdf[:url]}#{RESET}"
          end
          puts
        end

        puts
        puts "#{DIM}#{'═' * 70}#{RESET}"
        puts
      end

      def show_download_start(titulo, index, total)
        puts "  #{CYAN}[#{index}/#{total}]#{RESET} #{titulo}…"
      end

      def show_download_done(paths)
        puts
        puts "#{GREEN}#{BOLD}#{paths.size} arquivo(s) baixado(s) com sucesso:#{RESET}"
        paths.each { |p| puts "  #{DIM}#{p}#{RESET}" }
        puts
      end

      private

      def render_header(metadata)
        total_vagas   = metadata[:total_vagas]   || ''
        total_scraped = metadata[:total_scraped]
        encerrados    = metadata[:modo] == :encerrados
        busca         = metadata[:busca]

        titulo = encerrados ? 'CONCURSOS ENCERRADOS' : 'CONCURSOS PÚBLICOS ABERTOS'

        puts
        puts "#{BOLD}#{CYAN}╔══════════════════════════════════════════════════════════╗#{RESET}"
        puts "#{BOLD}#{CYAN}║  #{titulo.ljust(54)} ║#{RESET}"
        puts "#{BOLD}#{CYAN}║  #{Time.now.strftime('%d/%m/%Y').ljust(54)} ║#{RESET}"
        puts "#{BOLD}#{CYAN}╚══════════════════════════════════════════════════════════╝#{RESET}"
        puts
        puts "#{DIM}Busca: \"#{busca}\"#{RESET}"                        if busca
        puts "#{DIM}Fonte: pciconcursos.com.br  |  #{total_vagas}#{RESET}" unless total_vagas.empty?
        puts "#{DIM}#{total_scraped} resultado(s) encontrado(s).#{RESET}" if total_scraped
        puts
      end

      def render_concursos(concursos)
        puts "#{GREEN}#{BOLD}Exibindo #{concursos.size} concurso(s)#{RESET}"
        puts

        current_state = nil
        concursos.each_with_index do |c, i|
          if c.estado != current_state
            current_state = c.estado
            puts "\n#{BOLD}#{BLUE}\u25b6  #{current_state}#{RESET}"
            puts "#{DIM}#{'-' * 62}#{RESET}"
          end
          render_entry(c, i + 1)
        end
      end

      def render_entry(concurso, numero = nil)
        puts
        num_prefix = numero ? "#{BOLD}#{CYAN}[#{numero}]#{RESET} " : '  '
        puts "  #{num_prefix}#{BOLD}#{WHITE}#{concurso.instituicao}#{RESET}"

        vagas_line = if concurso.salario.empty?
                       concurso.vagas
                     else
                       "#{concurso.vagas}  #{YELLOW}#{concurso.salario}#{RESET}"
                     end

        puts "  #{YELLOW}Vagas :#{RESET} #{vagas_line}"
        puts "  #{YELLOW}Cargo :#{RESET} #{concurso.cargos}"        unless concurso.cargos.empty?
        puts "  #{YELLOW}Nível :#{RESET} #{concurso.nivel}"          unless concurso.nivel.empty?
        puts "  #{YELLOW}Prazo :#{RESET} #{RED}#{concurso.prazo}#{RESET}" unless concurso.prazo.empty?
        puts "  #{DIM}#{concurso.url}#{RESET}"                        if concurso.url
      end

      def render_footer(count)
        puts
        puts "#{DIM}#{'═' * 62}#{RESET}"
        puts "#{GREEN}#{BOLD}Total exibido: #{count} concurso(s)#{RESET}"
        puts
      end

      def wrap_text(text, width: 72, indent: 0)
        words  = text.split(' ')
        prefix = ' ' * indent
        lines  = []
        line   = ''

        words.each do |word|
          if line.empty?
            line = word
          elsif (line.length + 1 + word.length) <= (width - indent)
            line += " #{word}"
          else
            lines << line
            line = word
          end
        end
        lines << line unless line.empty?

        first = lines.shift || ''
        return first if lines.empty?

        ([first] + lines.map { |l| prefix + l }).join("\n")
      end
    end
  end
end
