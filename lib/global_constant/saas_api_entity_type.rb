# frozen_string_literal: true
module GlobalConstant

  class SaasApiEntityType

    ### Result types Start ###

    def self.result_transaction_type
      'transaction'
    end

    ### Result types Start ###


    ### Entity types End ###

    def transaction_entity_key
      'transaction'.to_sym
    end

    ### Entity types End ###


  end

end
