# frozen_string_literal: true

module Application
  module Ports
    class ConcursoRepository
      def fetch_abertos
        raise NotImplementedError, "#{self.class}#fetch_abertos deve ser implementado"
      end

      def fetch_encerrados(busca)
        raise NotImplementedError, "#{self.class}#fetch_encerrados deve ser implementado"
      end

      def fetch_edital(url)
        raise NotImplementedError, "#{self.class}#fetch_edital deve ser implementado"
      end

      def fetch_provas_listing(provas_url)
        raise NotImplementedError, "#{self.class}#fetch_provas_listing deve ser implementado"
      end

      def fetch_prova_pdfs(download_url)
        raise NotImplementedError, "#{self.class}#fetch_prova_pdfs deve ser implementado"
      end
    end
  end
end
