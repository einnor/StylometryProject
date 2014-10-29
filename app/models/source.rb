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

class Source < ActiveRecord::Base
  
  
  has_many :students
end
