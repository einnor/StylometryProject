class PagesController < ApplicationController
  
  before_filter  :authenticate_admin!
  def home
  end

  def about
  end

  def contactUS
  end
end
