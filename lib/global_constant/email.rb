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
        ['bala@ost.com', 'sunil@ost.com', 'kedar@ost.com', 'alpesh@ost.com', 'pankaj@ost.com', 'aman@ost.com']
      end

      def subject_prefix
        "CA #{Rails.env} : "
      end

    end

  end

end
