Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  scope 'api/client', controller: 'client/login' do
    match 'sign-up' => :sign_up, via: :POST
    match 'login' => :login, via: :POST
    match 'reset-password' => :reset_password, via: :POST
    match 'send-reset-password-link' => :send_reset_password_link, via: :POST
  end

  scope 'api/client', controller: 'client/setup' do
    match 'setup-eth-address' => :setup_eth_address, via: :POST
    match 'validate-eth-address' => :validate_eth_address, via: :GET
  end

  scope 'api/economy/token', controller: 'economy/token' do
    match 'create' => :create_token, via: :POST
    match 'plan' => :plan_token, via: :POST
    match 'stake-and-mint' => :stake_and_mint, via: :POST
  end

end
