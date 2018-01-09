# frozen_string_literal: true
module GlobalConstant

  class Email

    class << self

      def default_from
        Rails.env.production? ? 'notifier@simpletoken.org' : 'notifier@stagingsimpletoken.org'
      end

      def default_to
        ['bala@pepo.com', 'sunil@pepo.com', 'kedar@pepo.com', 'alpesh@pepo.com']
      end

      def subject_prefix
        "CA #{Rails.env} : "
      end

    end

  end

end
