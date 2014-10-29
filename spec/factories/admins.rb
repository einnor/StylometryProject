#spec/factories/admin.rb
require 'faker'
FactoryGirl.define do
  factory :admin do 
    email {Faker::Internet.email}
    encrypted_password '123'
  end
end