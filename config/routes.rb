Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  scope 'api/client', controller: 'client/login' do
    match 'verify-cookie' => :verify_cookie, via: :GET
    match 'sign-up' => :sign_up, via: :POST
    match 'login' => :login, via: :POST
    match 'logout' => :logout, via: :POST
    match 'reset-password' => :reset_password, via: :POST
    match 'send-reset-password-link' => :send_reset_password_link, via: :POST
    match 'verify-email' => :verify_email, via: :POST
  end

  scope 'api/client', controller: 'client/setup' do
    match 'validate-eth-address' => :validate_eth_address, via: :GET
    match 'get-ost' => :get_test_ost, via: :POST
    match 'get-eth' => :get_test_eth, via: :POST
  end

  scope 'api/economy/users', controller: 'economy/user' do
    match 'create' => :create_user, via: :POST
    match 'edit' => :edit_user, via: :POST
    match 'list' => :list_users, via: :GET
  end

  scope 'api/economy/token', controller: 'economy/token' do
    match 'get-setup-details' => :get_setup_details, via: :GET
    match 'get-supply-details' => :get_supply_details, via: :GET
    match 'plan' => :plan_token, via: :POST
    match 'log-transfer-to-staker' => :log_transfer_to_staker, via: :POST
    match 'stake-and-mint' => :stake_and_mint, via: :POST
  end

  scope 'api/economy/transaction/kind', controller: 'economy/transaction_kind' do
    match 'create' => :create, via: :POST
    match 'edit' => :edit, via: :POST
    match 'bulk-create-edit' => :bulk_create_edit, via: :POST
    match 'list' => :list, via: :GET
  end

  scope 'api/economy/transaction', controller: 'economy/transaction' do
    match 'execute' => :execute, via: :POST
    match 'history' => :fetch_history, via: :GET
  end

end
