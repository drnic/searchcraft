# frozen_string_literal: true

module SearchCraft
  class Error < StandardError; end
end

# dependencies of scenic gem without loading all of rails
require "delegate"
require "active_support/core_ext/module"
require "active_record/schema_dumper"

require_relative "searchcraft/version"
require_relative "searchcraft/builder"
require_relative "searchcraft/model"
