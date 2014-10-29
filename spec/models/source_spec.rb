# == Schema Information
#
# Table name: sources
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  url        :string(255)
#  created_at :datetime
#  updated_at :datetime
#

require 'rails_helper'

RSpec.describe Source, :type => :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
