class WebController < ApplicationController

  include ActionController::RequestForgeryProtection
  protect_from_forgery with: :exception

  include CsrfTokenConcern

  [
      ActionController::Cookies
  ].each do |mdl|
    include mdl
  end

  # this is the top-most wrapper - to catch all the exceptions at any level
  prepend_around_action :handle_exceptions_gracefully

  before_action :authenticate_request

  def delete_cookie(cookie_name)
    cookies.delete(cookie_name.to_sym, domain: :all, secure: !Rails.env.development?, same_site: :strict)
  end

  def set_cookie(cookie_name, value, expires)
    cookies[cookie_name.to_sym] = {
        value: value,
        expires: expires,
        domain: :all,
        http_only: true,
        secure: !Rails.env.development?,
        same_site: :strict
    }
  end

  private

  def authenticate_request
    fail 'Sub-class to implement.'
  end

  def handle_exceptions_gracefully

    begin

      yield

    rescue => se

      Rails.logger.error("Exception in API: #{se.message}")
      ApplicationMailer.notify(
          body: {exception: {message: se.message, backtrace: se.backtrace}},
          data: {
              'params' => params
          },
          subject: 'Exception in API'
      ).deliver

      r = Result::Base.exception(
        se,
        {
          error: 'swr',
          error_message: 'Something Went Wrong',
          data: params
        }
      )
      render_api_response(r)

    end

  end

end
