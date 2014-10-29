# == Schema Information
#
# Table name: students
#
#  id         :integer          not null, primary key
#  source_id  :integer
#  name       :string(255)
#  created_at :datetime
#  updated_at :datetime
#  essay      :string(255)
#

require 'rails_helper'

RSpec.describe Student, :type => :model do
  
  
  
end
