# frozen_string_literal: true
module GlobalConstant

  class Email

    class << self

      def default_from
        if Rails.env.production?
          if GlobalConstant::Base.sub_env == GlobalConstant::Environment.main_sub_environment
            'notifier@ost.com'
          else
            'sandbox.notifier@ost.com'
          end
        else
          'staging.notifier@ost.com'
        end
      end

      def default_to
        ['backend@ost.com']
      end

      def subject_prefix
        "[#{GlobalConstant::Base.env_identifier}] company-api :: #{Rails.env} - #{GlobalConstant::Base.sub_env} :: "
      end

    end

  end

end
