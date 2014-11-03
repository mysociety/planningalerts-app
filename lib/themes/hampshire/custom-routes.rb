Rails.application.routes.draw do
  # include authority & reference number in applications page url
  # (keep original route too)
  match '/applications/:id/:authority/:reference' => 'applications#show', :constraints => {:reference => /.*/}, :as => :council_reference_application

  # override existing applications resources to allow POSTs to :search
  resources :applications, :only => [:show] do
    collection do
      get :search
      post :search
    end
  end

  # Override the homepage to go straight to application search
  root :to => 'applications#search'

  # switch off routes not used by the theme
  match 'applications', :to => 'static#error_404'

  match 'authorities/:id/applications', :to => 'static#error_404'

  match 'faq', :to => 'static#error_404'
  match 'getinvolved', :to => 'static#error_404'
  match 'how_to_write_a_scraper', :to => 'static#error_404'
  match 'how_to_lobby_your_local_council', :to => 'static#error_404'

  match 'donate', :to => 'static#error_404'
  match 'donate/:catchall', :to => 'static#error_404'

  match 'api', :to => 'static#error_404'
  match 'api/:catchall', :to => 'static#error_404'

  match 'alerts', :to => 'static#error_404'
  match 'alerts/:catchall', :to => 'static#error_404'
  match 'alerts/:id/:verb', :to => 'static#error_404'

  match 'comments', :to => 'static#error_404'
  match 'comments/:catchall', :to => 'static#error_404'
  match 'comments/:id/:verb', :to => 'static#error_404'

  match 'atdis', :to => 'static#error_404'
  match 'atdis/:catchall', :to => 'static#error_404'
  match 'atdis/feed/:number/atdis/1.0/applications.json', :to => 'static#error_404'

  match '/layar/getpoi', :to => 'static#error_404'
end