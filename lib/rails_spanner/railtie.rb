require 'rails_spanner'
require 'rails'

module RailsSpanner
  class Railtie < Rails::Railtie
    railtie_name :rails_spanner

    rake_tasks do
      load "tasks/rails_spanner_tasks.rake"
    end
  end
end
