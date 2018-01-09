class ApiController < ApplicationController

  # this is the top-most wrapper - to catch all the exceptions at any level
  prepend_around_action :handle_exceptions_gracefully

  before_action :validate_cookie

  private

  def validate_cookie
    fail 'Sub-class to implement.'
  end

  def handle_exceptions_gracefully

    begin

      yield

    rescue => se

      Rails.logger.error("Exception in Company API: #{se.message}")
      ApplicationMailer.notify(
          body: {exception: {message: se.message, backtrace: se.backtrace}},
          data: {
              'params' => params
          },
          subject: 'Exception in Company API'
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
