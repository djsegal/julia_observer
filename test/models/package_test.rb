# == Schema Information
#
# Table name: packages
#
#  id          :bigint           not null, primary key
#  created     :datetime
#  description :string
#  name        :string
#  stars       :integer
#  updated     :datetime
#  website     :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
require 'test_helper'

class PackageTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end