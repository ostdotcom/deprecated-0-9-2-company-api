module Economy

  module TransactionKind

    class Base < ServicesBase

      # Initialize
      #
      # * Author: Puneet
      # * Date: 29/01/2018
      # * Reviewed By:
      #
      # @params [String] client_id (mandatory) - client_id
      #
      # @return [Economy::TransactionKind::Base]
      #
      def initialize(params)

        super

        @client_id = @params[:client_id]

        @ost_sdk_obj = nil
        @ost_spec_sdk_obj = nil
      end

      # Perform
      #
      # * Author: Puneet
      # * Date: 29/01/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def perform

        r = validate
        return r unless r.success?

        instantiate_ost_sdk

      end

      private

      # Perform
      #
      # * Author: Puneet
      # * Date: 29/01/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def instantiate_ost_sdk

        result = CacheManagement::ClientApiCredentials.new([@client_id]).fetch[@client_id]
        return  validation_error(
            'e_tk_b_1',
            'invalid_api_params',
            ['invalid_client_id'],
            GlobalConstant::ErrorAction.default
        ) if result.blank?

        # Create OST Sdk Obj
        ost_sdk = OSTSdk::Saas::Services.new(
            api_key: result[:api_key],
            api_secret: result[:api_secret],
            api_base_url: "#{GlobalConstant::SaasApi.base_url}v1",
            api_spec: false
        )
        @ost_sdk_obj = ost_sdk.manifest.actions

        # Create OST Sdk Spec Obj
        ost_sdk = OSTSdk::Saas::Services.new(
            api_key: result[:api_key],
            api_secret: result[:api_secret],
            api_base_url: "#{GlobalConstant::SaasApi.base_url}v1",
            api_spec: true
        )
        @ost_spec_sdk_obj = ost_sdk.manifest.actions

        success

      end

      # Sanitize Create / Edit Params
      #
      # * Author: Puneet
      # * Date: 29/01/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def sanitize_create_edit_params!

        @params.delete(:client_id)
        @params.delete(:commission_percent) if @params[:commission_percent].to_f == 0
        @params.delete(:amount) if @params[:amount].to_f == 0

        success

      end

    end

  end

end