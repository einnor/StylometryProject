# == Schema Information
#
# Table name: students
#
#  id            :integer          not null, primary key
#  source_id     :integer
#  name          :string(255)
#  created_at    :datetime
#  updated_at    :datetime
#  essay         :string(255)
#  essayEvaluate :string(255)
#

class Student < ActiveRecord::Base
  belongs_to :source
  
  mount_uploader :essay, EssayUploader
  mount_uploader :essayEvaluate, EssayEvaluateUploader
  
  validates :source_id, presence: true
  validates :name, presence: true
  validates :essay, presence: true
  validates :essayEvaluate, presence: false
  
end
