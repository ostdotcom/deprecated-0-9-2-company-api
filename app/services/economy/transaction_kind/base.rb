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

        r = ClientManagement::GetClientApiCredentials.new(client_id: @client_id).perform
        return unless r.success?

        # Create OST Sdk Obj
        credentials = OSTSdk::Util::APICredentials.new(r.data[:api_key], r.data[:api_secret])
        @ost_sdk_obj = OSTSdk::Saas::TransactionKind.new(GlobalConstant::Base.sub_env, credentials)

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