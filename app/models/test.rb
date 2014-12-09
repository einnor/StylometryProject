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

class Test < ActiveRecord::Base
  belongs_to :student
  mount_uploader :evaluate, EvaluateUploader
end
