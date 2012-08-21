# desc "Explaining what the task does"
# task :rails_spanner do
#   # Task goes here
# end

namespace :rails do
  namespace :spanner do

    namespace :analytics do
      desc "model associations"
      task :model_associations => :environment do
        # ActiveRecord::Base.ancestors.find_all {|c| c.class.is_a?(Class)}
        @models = find_models
        @to_analytics = @models.dup
        while (model = @to_analytics.pop) do
          show_associations_for_model(model)
          puts ""
        end
        puts "Total #{@models.size} models"
      end

      def find_models
        files = Dir.glob(("app/models/**/*.rb"))
        models = []
        files.each do |f|
          begin
            current_class = extract_class_name(f).constantize
            model = identify_model(current_class)
            models << model if model
          rescue Exception
            STDERR.puts "Warning: exception #{$!} raised while trying to load model class #{f}"
            # debugger
            # current_class
          end
        end
        models
      end

      # Extract class name from filename
      def extract_class_name(filename)
        #filename.split('/')[2..-1].join('/').split('.').first.camelize
        # Fixed by patch from ticket #12742
        # File.basename(filename).chomp(".rb").camelize
        filename.split('/')[2..-1].collect { |i| i.camelize }.join('::').chomp(".rb")
      end

      # Process a model class
      def identify_model(current_class)
        return false unless current_class.is_a?(Class)
        if current_class < ActiveRecord::Base
          current_class # is a active_record_model
        elsif current_class < ActiveRecord::Observer

        else
          if defined?(Mongoid::Document) && current_class.new.is_a?(Mongoid::Document) # including Mongoid::History::Tracker
            current_class # is a mongoid_model
          elsif defined?(DataMapper::Resource) && current_class.new.is_a?(DataMapper::Resource)
            current_class # is a datamapper_model
          elsif current_class.respond_to? 'reflect_on_all_associations'
            current_class # is a active_record_model
          end
        end
      end

      def show_associations_for_model(model)
        if !model.respond_to? :base_class
          puts "#{model.name} is not a ActiveRecord Model"
          return false
        end

        if model.base_class == model
          puts "#{model.name} associations:"
        else # is a sti class
          puts "#{model.name} < #{model.base_class} associations:"
        end

        model.reflect_on_all_associations.group_by(&:macro).each  do |type, associations|
          puts "  #{type}:"
          associations.each do |asso|
            asso_model = nil
            if asso.options[:through] # has_many: through
              # asso.association_class # ActiveRecord::Associations::HasManyThroughAssociation
              asso_model = asso.through_reflection.klass
              puts "    #{asso.name} => (through) #{asso.options[:through]} (#{asso_model.name})"
            else
              if asso.options[:polymorphic]
                if type == :belongs_to
                  puts "    #{asso.name} (polymorphic)"
                else
                  asso_model = asso.klass
                  puts "    #{asso.name} => #{asso_model.name} (polymorphic)"
                end
              else
                asso_model = asso.klass
                puts "    #{asso.name} => #{asso_model.name}"
              end
            end
            add_to_models(asso_model) if asso_model
          end
        end
      end

      def add_to_models(model)
        if !@models.include?(model) && model.is_a?(Class)
          @models << model
          @to_analytics << model
        end
      end
    end

  end
end