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
        return error_with_data(
            'e_tk_b_1',
            "Invalid client.",
            'Something Went Wrong.',
            GlobalConstant::ErrorAction.default,
            {}
        ) if result.blank?

        # Create OST Sdk Obj
        credentials = OSTSdk::Util::APICredentials.new(result[:api_key], result[:api_secret])
        @ost_sdk_obj = OSTSdk::Saas::TransactionKind.new(GlobalConstant::Base.sub_env, credentials)
        @ost_spec_sdk_obj = OSTSdk::Saas::TransactionKind.new(GlobalConstant::Base.sub_env, credentials, true)

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

        success

      end

    end

  end

end