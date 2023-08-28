require "test_helper"

describe SearchCraft::Builder do
  it "finds builders that not directly subclasses of SearchCraft::Builder" do
    builder_class_names = SearchCraft::Builder.find_subclasses_via_rails_eager_load_paths
    assert_includes builder_class_names, "InheritanceDemo::BaseclassBuilder"
    assert_includes builder_class_names, "InheritanceDemo::SubclassBuilder"
  end
end
