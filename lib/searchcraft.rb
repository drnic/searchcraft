# frozen_string_literal: true

module SearchCraft
  class Error < StandardError; end
end

require "active_record"

require_relative "searchcraft/version"
require_relative "searchcraft/annotate"
require_relative "searchcraft/depends_on"
require_relative "searchcraft/builder"
require_relative "searchcraft/model"
require_relative "searchcraft/view_hash_store"
require_relative "searchcraft/railtie" if defined?(Rails)
