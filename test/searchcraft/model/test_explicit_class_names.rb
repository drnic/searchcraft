# frozen_string_literal: true

require "test_helper"

class ExplicitModel < ActiveRecord::Base
  include SearchCraft::Model
end

describe SearchCraft::Model do
  it "explicitly declares class names in config" do
    config = SearchCraft::Configuration.new
    config.explicit_model_class_names = ["ExplicitModel"]

    SearchCraft.stub :config, config do
      assert_includes SearchCraft::Model.included_classes, ExplicitModel
    end
  end
end
