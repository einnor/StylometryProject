# == Schema Information
#
# Table name: tests
#
#  id         :integer          not null, primary key
#  created_at :datetime
#  updated_at :datetime
#  evaluate   :string(255)
#  student_id :integer
#

require 'rails_helper'

RSpec.describe Test, :type => :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
