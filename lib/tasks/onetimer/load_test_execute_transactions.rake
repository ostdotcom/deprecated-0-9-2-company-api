namespace :one_timers do

  desc 'Usage -> rake RAILS_ENV=development one_timers:load_test_execute_transactions'

  task :load_test_execute_transactions => :environment do

    def init_variables

      @txs_to_execute = 1000
      @no_of_concurrrent_txs = 50

      @transaction_kind_names = []

      # @client_id = 1043
      # result = CacheManagement::ClientApiCredentials.new([@client_id]).fetch[@client_id]
      # credentials = OSTSdk::Util::APICredentials.new(result[:api_key], result[:api_secret])

      ost_sdk = OSTSdk::Saas::Services.new(
          api_key: '094785cedc1d78bcee10',
          api_secret: '6d2e6784d614c0a9aa13c5758633ec98932a5b3305b0bc378ddaae97efa46e88',
          api_base_url: 'http://devcompany.com:7001/',
          api_spec: false
      )

      @user_sdk_obj = ost_sdk.services.users
      @tx_kind_sdk_obj = ost_sdk.services.actions
      @transactions_sdk_obj = ost_sdk.services.transactions

    end

    def create_dummy_users
      i = 0
      while true
        SaasApi::OnBoarding::CreateDummyUsers.new.perform(client_id: 1105, number_of_users: 25)
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
          puts "setting page_no: #{page_no}"
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
            api_spec_service_response = @transactions_sdk_obj.execute(api_params)
          end
          procs_length += 1
          break if procs_length >= @txs_to_execute
        end

        puts procs_length
        break if procs_length >= @txs_to_execute
      end
      puts @no_of_concurrrent_txs
      parallelProcessed = ParallelProcessor.new(@no_of_concurrrent_txs, procs).perform
      # puts parallelProcessed.data
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
