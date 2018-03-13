namespace :one_timers do

  desc 'Usage -> rake RAILS_ENV=development one_timers:load_test_execute_transactions'

  task :load_test_execute_transactions => :environment do

    def init_variables

      @txs_to_execute = 900
      @no_of_concurrrent_txs = 75

      @transaction_kind_names = []

      # @client_id = 1043
      # result = CacheManagement::ClientApiCredentials.new([@client_id]).fetch[@client_id]
      # credentials = OSTSdk::Util::APICredentials.new(result[:api_key], result[:api_secret])

      api_key = '8164d6ab1f479db3a10e'
      api_secret = 'a8730c94f916ad95351b0182d246e996315eba5be2353dd11e5f9ad5a6331240'

      credentials = OSTSdk::Util::APICredentials.new(api_key, api_secret)
      @user_sdk_obj = OSTSdk::Saas::Users.new(GlobalConstant::Base.sub_env, credentials)
      @tx_kind_sdk_obj = OSTSdk::Saas::TransactionKind.new(GlobalConstant::Base.sub_env, credentials)

    end

    def create_dummy_users
      i = 0
      while true
        SaasApi::OnBoarding::CreateDummyUsers.new.perform(client_id: @client_id, number_of_users: 25)
        i = i + 1
        break if i == 40
      end
    end

    def fetch_tx_names

      return if @transaction_kind_name.present?

      @transaction_kind_names = []
      @tx_kind_sdk_obj.list.data['transaction_types'].each do |tx|
        @transaction_kind_names << tx['name'] if tx['kind'] == 'user_to_user'
      end

      @transaction_kind_names = @transaction_kind_names.shuffle

      puts @transaction_kind_names

    end

    def fetch_user_uuids
      @uuids = []
      page_no = 1
      while true
        r = @user_sdk_obj.list(page_no: page_no)
        break unless r.success?
        @uuids += r.data['economy_users'].map{|k| k['uuid']}
        if r.data['meta']['next_page_payload'].present? && r.data['meta']['next_page_payload']['page_no'].present?
          page_no = r.data['meta']['next_page_payload']['page_no']
        else
          break
        end
      end

      puts @uuids
    end

    def execute_transactions
      procs = {}
      procs_length = 0
      transaction_kind_names_length = @transaction_kind_names.length
      while true
        half_length = @uuids.length / 2

        (half_length-1).times do |i|
          j = 2*i

          transaction_kind_name = @transaction_kind_names[Random.rand(transaction_kind_names_length)]

          from_uuid = @uuids[j]
          to_uuid = @uuids[j+1] || @uuids[0]

          api_params = {
            from_uuid: from_uuid,
            to_uuid: to_uuid,
            transaction_kind: transaction_kind_name
          }

          procs[procs_length] = Proc.new do
            api_spec_service_response = @tx_kind_sdk_obj.execute(api_params)
          end
          procs_length += 1
        end

        puts procs_length
        break if procs_length >= @txs_to_execute
      end
      puts @no_of_concurrrent_txs
      parallelProcessed = ParallelProcessor.new(@no_of_concurrrent_txs, procs).perform
      puts parallelProcessed.data
    end

    def perform
      init_variables
      # create_dummy_users
      fetch_tx_names
      fetch_user_uuids
      execute_transactions
    end

    perform

  end

end
