module CsrfTokenConcern

  extend ActiveSupport::Concern

  def handle_unverified_request

    ApplicationMailer.notify(
        body: 'Invalid Authenticity Token Exception',
        data: {
            controller: params[:controller],
            action: params[:action],
            authenticity_token: params[:authenticity_token],
            http_user_agent: http_user_agent,
            request_time: Time.now,
            page_loaded_at: params[:page_loaded_at]
        },
        subject: 'InvalidAuthenticityToken'
    ).deliver

    r = Result::Base.error(
        {
            error: 'invalid_authenticity_token',
            error_message: 'Session has expired. Please refresh your page.',
            error_data: {},
            error_action: GlobalConstant::ErrorAction.default,
            error_display_text: 'Session has expired. Please refresh your page.',
            error_display_heading: 'Error',
            data: {}
        }
    )
    render_api_response(r)
  end

end