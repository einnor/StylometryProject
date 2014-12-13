class PagesController < ApplicationController
  
  before_filter  :authenticate_admin!, only: [:home]
  
  # Landing page
  def index
    if signed_in?
      redirect_to students_path
      return
    else
      # Make Login page the default page
     redirect_to new_admin_session_path
    end
    #render(:layout => "layouts/landing")
  end
  
  def home
  end

  def about
  end

  def contactUS
  end
end
