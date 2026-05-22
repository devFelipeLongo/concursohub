# frozen_string_literal: true

module Application
  module Ports
    class Presenter
      def show_loading
        raise NotImplementedError, "#{self.class}#show_loading deve ser implementado"
      end

      def show(concursos, metadata: {})
        raise NotImplementedError, "#{self.class}#show deve ser implementado"
      end

      def error(message)
        raise NotImplementedError, "#{self.class}#error deve ser implementado"
      end

      def show_edital(edital)
        raise NotImplementedError, "#{self.class}#show_edital deve ser implementado"
      end

      def show_download_start(titulo, index, total)
        raise NotImplementedError, "#{self.class}#show_download_start deve ser implementado"
      end

      def show_download_done(paths)
        raise NotImplementedError, "#{self.class}#show_download_done deve ser implementado"
      end

      def show_provas(provas)
        raise NotImplementedError, "#{self.class}#show_provas deve ser implementado"
      end
    end
  end
end
