class ApplicationSearch
  # Modelling a search that a user makes, so that we can encapsulate the logic
  # for processing the input and performing the search

  # In theory, this could allow us to make theme overriding of searches easier
  # because themes can point at a config variable like THEME_SEARCH_MODEL and
  # then subclass this to do stuff differently.
  extend  ActiveModel::Naming
  extend  ActiveModel::Translation
  include ActiveModel::Validations
  include ActiveModel::Conversion

  attr_accessor :search, :page

  def perform_search(override_params={})
    raise 'You should implement this in your Search subclass'
  end
end