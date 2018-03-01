class ApplicationController < ActionController::API

  # this is the top-most wrapper - to catch all the exceptions at any level
  prepend_around_action :handle_exceptions_gracefully

  # Sanitize URL params
  include Sanitizer

  before_action :sanitize_params

  after_action :set_response_headers

  def not_found
    r = Result::Base.error({
                               error: 'ac_1',
                               error_message: 'Resource not found',
                               http_code: GlobalConstant::ErrorCode.not_found
                           })
    render_api_response(r)
  end

  private

  def sanitize_params
    sanitize_params_recursively(params)
  end

  def http_user_agent
    # User agent is required for cookie validation
    request.env['HTTP_USER_AGENT'].to_s
  end

  def ip_address
    request.remote_ip.to_s
  end

  def set_response_headers
    response.headers["X-Robots-Tag"] = 'noindex, nofollow'
    response.headers["Content-Type"] = 'application/json; charset=utf-8'
  end

  # Render API response
  #
  # * Author: Kedar
  # * Date: 24/01/2018
  # * Reviewed By: Aman
  #
  def render_api_response(service_response)
    # calling to_json of Result::Base
    response_hash = service_response.to_json
    http_status_code = service_response.http_code

    # filter out not allowed http codes
    http_status_code = GlobalConstant::ErrorCode.ok unless GlobalConstant::ErrorCode.allowed_http_codes.include?(http_status_code)

    # sanitizing out error and data. only display_text and display_heading are allowed to be sent to FE.
    if !service_response.success? && !Rails.env.development?
      err = response_hash.delete(:err) || {}
      response_hash[:err] = {
          display_text: (err[:display_text].to_s),
          display_heading: (err[:display_heading].to_s),
          error_data: (err[:error_data] || {})
      }

      response_hash[:data] = {}
    end

    if !service_response.success? && service_response.go_to.present?
      response_hash[:err][:go_to] = service_response.go_to
    end

    (render plain: Oj.dump(response_hash, mode: :compat), status: http_status_code)

  end

  # Handle exceptions gracefully
  #
  # * Author: Kedar
  # * Date: 24/01/2018
  # * Reviewed By: Aman
  #
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
