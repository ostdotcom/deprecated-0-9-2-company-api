namespace :one_timers do

  desc 'Usage -> rake RAILS_ENV=development one_timers:load_test_execute_transactions'

  task :load_test_execute_transactions => :environment do

    def init_variables

      @txs_to_execute = 10
      @no_of_concurrrent_txs = 2

      @action_ids = []

      # @client_id = 1043
      # result = CacheManagement::ClientApiCredentials.new([@client_id]).fetch[@client_id]
      # credentials = OSTSdk::Util::APICredentials.new(result[:api_key], result[:api_secret])

      ost_sdk = OSTSdk::Saas::Services.new(
          api_key: '07d12e3a0459259e8f95',
          api_secret: 'fefc78bcca090b7508171e4e38edcee66ee3dcbbf536eb41abbaf1423cc5a022',
          api_base_url: 'https://playgroundapi.stagingost.com/v1',
          api_spec: false
      )

      @user_sdk_obj = ost_sdk.services.users
      @tx_kind_sdk_obj = ost_sdk.services.actions
      @transactions_sdk_obj = ost_sdk.services.transactions

    end

    def create_dummy_users
      i = 0
      while true
        SaasApi::OnBoarding::CreateDummyUsers.new.perform(client_id: 1172, number_of_users: 2)
        i = i + 1
        break if i == 1
      end
    end

    def fetch_tx_names

      return if @action_ids.present?

      @action_ids = []
      @tx_kind_sdk_obj.list.data['actions'].each do |tx|
        @action_ids << tx['id'] if tx['kind'] == 'user_to_user'
      end

      @action_ids = @action_ids.shuffle

      puts @action_ids.inspect

    end

    def fetch_user_uuids
      @uuids = []
      page_no = 1
      while true
        r = @user_sdk_obj.list(page_no: page_no)
        puts r.inspect
        break unless r.success?
        @uuids += r.data['users'].map{|k| k['id']}
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
      action_ids_length = @action_ids.length
      while true
        half_length = @uuids.length / 2

        (half_length-1).times do |i|
          j = 2*i

          action_id = @action_ids[Random.rand(action_ids_length)]

          from_user_id = @uuids[j]
          to_user_id = @uuids[j+1] || @uuids[0]

          api_params = {
            from_user_id: from_user_id,
            to_user_id: to_user_id,
            action_id: action_id
          }

          puts "api_params--->#{api_params.inspect}"

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
