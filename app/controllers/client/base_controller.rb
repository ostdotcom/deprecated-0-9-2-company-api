class Client::BaseController < WebController

  private

  def verify_recaptcha
    service_response = Recaptcha::Verify.new({
                                                 'response' => params['g-recaptcha-response'].to_s,
                                                 'remoteip' => request.remote_ip.to_s
                                             }).perform

    Rails.logger.info('---- Recaptcha::Verify done')

    unless service_response.success?
      render_api_response(service_response)
    end

    Rails.logger.info('---- check_recaptcha_before_verification done')

  end

end