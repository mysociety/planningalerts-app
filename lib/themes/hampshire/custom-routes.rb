Rails.application.routes.draw do
  match '/applications/:id/:authority/:reference' => 'applications#show', :constraints => {:reference => /.*/}
end