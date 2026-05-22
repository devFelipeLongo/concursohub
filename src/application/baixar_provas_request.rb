# frozen_string_literal: true

module Application
  BaixarProvasRequest = Struct.new(:url, :dest_dir, keyword_init: true)
end
