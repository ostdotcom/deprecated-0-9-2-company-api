Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  scope 'api/client', controller: 'client/login' do
    match 'sign-up' => :sign_up, via: :POST
    match 'login' => :login, via: :POST
  end

end
