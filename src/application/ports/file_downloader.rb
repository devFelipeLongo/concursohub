# frozen_string_literal: true

module Application
  module Ports
    class FileDownloader
      def download(url, dest_path)
        raise NotImplementedError, "#{self.class}#download deve ser implementado"
      end
    end
  end
end
