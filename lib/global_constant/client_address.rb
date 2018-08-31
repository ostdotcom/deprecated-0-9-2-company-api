# frozen_string_literal: true
module GlobalConstant

  class ClientAddress

    class << self

      ### Status Start ###

      def active_status
        'active'
      end

      def inactive_status
        'inactive'
      end

      ### Status End ###

      def default_first_time_ost_grant_amount
        if Rails.env.production?
          if GlobalConstant::Base.sub_env == 'main'
            #TODO - ask Junisha
            return 10
          else
            return 10000
          end
        else
          return 10000
        end
      end

      def default_recurring_ost_grant_amount
        if Rails.env.production?
          if GlobalConstant::Base.sub_env == 'main'
            #TODO - ask Junisha
            return 10
          else
            return 10000
          end
        else
          return 10000
        end
      end

      def default_eth_grant_amount
        if Rails.env.production?
          if GlobalConstant::Base.sub_env == 'main'
            #TODO - ask Junisha
            return 0.0006
          else
            return 1
          end
        else
          return 0.1
        end
      end

    end

  end

end
