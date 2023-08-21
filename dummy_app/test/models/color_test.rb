# == Schema Information
#
# Table name: colors
#
#  id         :bigint           not null, primary key
#  css_class  :string           not null
#  label      :string           not null
#  position   :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require "test_helper"

class ColorTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
