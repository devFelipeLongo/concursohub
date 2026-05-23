# frozen_string_literal: true

require 'nokogiri'
require_relative '../../domain/entities/concurso'
require_relative '../../domain/entities/edital'

module Infrastructure
  module Parsers
    class PciHtmlParser
      def parse_abertos(html)
        doc = Nokogiri::HTML(html, nil, 'UTF-8')
        [extract_abertos(doc), { total_vagas: extract_total_vagas(doc) }]
      end

      def parse_encerrados(html)
        doc = Nokogiri::HTML(html, nil, 'UTF-8')
        concursos = doc.css('div.ea').filter_map { |el| build_concurso_encerrado(el) }
        [concursos, { total_vagas: '' }]
      end

      def parse_edital(html, url)
        doc     = Nokogiri::HTML(html, nil, 'UTF-8')
        article = doc.css('article#noticia').first

        raise "Edital não encontrado na página: #{url}" unless article

        titulo    = article.css('h1[itemprop="headline"]').first&.text&.strip || ''
        descricao = article.css('div.description').first&.text&.strip          || ''
        data_raw  = article.css('abbr.published').first&.[]('title')           || ''
        data_pub  = format_date(data_raw)

        body_node = article.css('div[itemprop="articleBody"]').first
        blocos    = body_node ? extract_body_blocks(body_node) : []

        Domain::Entities::Edital.new(
          titulo:          titulo,
          descricao:       descricao,
          data_publicacao: data_pub,
          blocos:          blocos,
          pdfs:            extract_pdfs(doc),
          provas_url:      extract_provas_url(doc),
          url:             url
        )
      end

      def parse_provas_listing(html)
        doc = Nokogiri::HTML(html, nil, 'UTF-8')
        doc.css('a.prova_download').map do |a|
          cargo = a.children.select(&:text?).map(&:text).join.strip
          { cargo: cargo, download_url: a['href'] }
        end
      end

      def parse_prova_download_page(html)
        doc = Nokogiri::HTML(html, nil, 'UTF-8')
        doc.css('div#download a.item-link[href$=".pdf"]')
           .select { |a| a.text.strip.start_with?('Baixar') }
           .map    { |a| { titulo: a.text.sub(/\ABaixar\s+/i, '').strip, url: a['href'] } }
      end

      private

      def extract_total_vagas(doc)
        doc.css('h1').first&.text&.match(/[\d.]+\s*Vagas?/i)&.[](0) || ''
      end

      def extract_abertos(doc)
        nacional = doc.css('#NACIONAL').first
        return [] unless nacional

        concursos     = []
        current_state = 'NACIONAL'

        nacional.parent.children.each do |child|
          next unless child.element?

          case child['class']&.strip
          when 'ua'
            current_state = child['id'] || 'NACIONAL'
          when 'da', 'na'
            entry = build_concurso(child, current_state)
            concursos << entry if entry
          end
        end

        concursos
      end

      def build_concurso_encerrado(el)
        link = el.css('div.ca > a[href^="/concurso/"]').first
        return nil unless link

        state = el.css('div.cc').first&.text&.strip || ''
        vagas, salario = parse_vagas_salario(el)
        cargos, nivel  = parse_cargo_nivel(el)

        Domain::Entities::Concurso.new(
          instituicao: link.text.strip,
          estado:      state,
          vagas:       vagas,
          salario:     salario,
          cargos:      cargos,
          nivel:       nivel,
          prazo:       parse_prazo(el),
          url:         link['href']
        )
      end
      def build_concurso(el, state)
        link = el.css('div.ca > a[href^="/concurso/"]').first
        return nil unless link

        vagas, salario = parse_vagas_salario(el)
        cargos, nivel  = parse_cargo_nivel(el)

        Domain::Entities::Concurso.new(
          instituicao: link.text.strip,
          estado:      state,
          vagas:       vagas,
          salario:     salario,
          cargos:      cargos,
          nivel:       nivel,
          prazo:       parse_prazo(el),
          url:         link['href']
        )
      end

      def parse_vagas_salario(el)
        cd = el.css('div.cd').first
        return ['', ''] unless cd

        text = cd.xpath('text()[1]').text.strip
        if text =~ /^(.+?)\s+(até R\$.+)$/
          [$1.strip, $2.strip]
        else
          [text, '']
        end
      end

      def parse_cargo_nivel(el)
        cd = el.css('div.cd').first
        return ['', ''] unless cd

        outer = cd.children.find { |c| c.element? && c.name == 'span' }
        return ['', ''] unless outer

        cargos = outer.xpath('text()[1]').text.strip
        nivel  = outer.children
                      .find { |c| c.element? && c.name == 'span' }
                      &.text&.strip || ''
        [cargos, nivel]
      end

      def parse_prazo(el)
        span = el.css('div.ce span').first
        return '' unless span

        span.children.map { |c|
          c.element? && c.name == 'br' ? ' ' : c.text
        }.join.gsub(/\s+/, ' ').strip
      end

      def extract_pdfs(doc)
        doc.css('aside#links li.pdf a').map do |a|
          { titulo: a.text.strip, url: a['href'] }
        end
      end

      def extract_provas_url(doc)
        doc.css('aside#links li.li_provas a').first&.[]('href')
      end

      def format_date(iso_str)
        return '' if iso_str.nil? || iso_str.empty?

        parts = iso_str[0..9].split('-')
        return iso_str unless parts.length == 3

        parts.reverse.join('/')
      end

      # Converte nós filhos de um articleBody em blocos estruturados.
      # Cada bloco: { tipo: :secao | :paragrafo | :item, texto: String }
      def extract_body_blocks(node)
        blocos = []
        node.children.each do |child|
          next unless child.element?

          case child.name
          when 'p'
            text = child.text.strip.gsub(/\s+/, ' ')
            blocos << { tipo: :paragrafo, texto: text } unless text.empty?
          when 'h2', 'h3', 'h4'
            text = child.text.strip
            blocos << { tipo: :secao, texto: text } unless text.empty?
          when 'ul', 'ol'
            child.css('li').each do |li|
              text = li.text.strip.gsub(/\s+/, ' ')
              blocos << { tipo: :item, texto: text } unless text.empty?
            end
          when 'div'
            blocos.concat(extract_body_blocks(child))
          end
        end
        blocos
      end
    end
  end
end
