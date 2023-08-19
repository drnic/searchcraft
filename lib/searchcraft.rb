# frozen_string_literal: true

module SearchCraft
  class Error < StandardError; end
end

require_relative "searchcraft/version"
require_relative "searchcraft/builder"
require_relative "searchcraft/model"
