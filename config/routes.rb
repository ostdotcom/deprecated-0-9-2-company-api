Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  scope 'api/client', controller: 'client/login' do
    match 'sign-up' => :sign_up, via: :POST
    match 'login' => :login, via: :POST
    match 'logout' => :logout, via: :POST
    match 'reset-password' => :reset_password, via: :POST
    match 'send-reset-password-link' => :send_reset_password_link, via: :POST
    match 'verify-email' => :verify_email, via: :POST
  end

  scope 'api/client', controller: 'client/setup' do
    match 'setup-eth-address' => :setup_eth_address, via: :POST
    match 'validate-eth-address' => :validate_eth_address, via: :GET
  end

  scope 'api/client/users', controller: 'client/user' do
    match 'create' => :create_user, via: :POST
    match 'edit' => :edit_user, via: :POST
  end

  scope 'api/economy/token', controller: 'economy/token' do
    match 'create' => :create_token, via: :POST
    match 'plan' => :plan_token, via: :POST
    match 'log-transfer-to-staker' => :log_transfer_to_staker, via: :POST
    match 'stake-and-mint' => :stake_and_mint, via: :POST
    match 'get-setup-status' => :get_setup_status, via: :GET
  end

  scope 'api/economy/transaction/kind', controller: 'economy/transaction_kind' do
    match 'create' => :create, via: :POST
    match 'edit' => :edit, via: :POST
    match 'list' => :list, via: :GET
  end

end
