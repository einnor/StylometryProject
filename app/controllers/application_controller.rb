class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  
  
  before_action if: :devise_controller?
    layout :layout_by_resource
  
  
  
  # Private methods
  protected

  def layout_by_resource
    if devise_controller? and !admin_signed_in?
      'landing'
    else
      'application'
    end
  end
end
