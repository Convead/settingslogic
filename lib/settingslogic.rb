require "yaml"
require "erb"

# A simple settings solution using a YAML file. See README for more information.
class Settingslogic < Hash
  class << self
    def name # :nodoc:
      instance.key?("name") ? instance.name : super
    end
    
    def source(value = nil)
      if value.nil?
        @source
      else
        @source = value
      end
    end
    
    def namespace(value = nil)
      if value.nil?
        @namespace
      else
        @namespace = value
      end
    end
    
    private
      def instance
        @instance ||= new
      end
      
      def method_missing(name, *args, &block)
        instance.send(name, *args, &block)
      end
  end
  
  # Initializes a new settings object. You can initialize an object in any of the following ways:
  #
  #   Settings.new(:application) # will look for config/application.yml
  #   Settings.new("application.yaml") # will look for application.yaml
  #   Settings.new("/var/configs/application.yml") # will look for /var/configs/application.yml
  #   Settings.new(:config1 => 1, :config2 => 2)
  #
  # Basically if you pass a symbol it will look for that file in the configs directory of your rails app, if you are using this in rails. If you pass a string it should be an absolute path to your settings file.
  # Then you can pass a hash, and it just allows you to access the hash via methods.
  def initialize(hash_or_file = self.class.source)
    case hash_or_file
    when Hash
      self.update hash_or_file
    else
      hash = YAML.load(ERB.new(File.read(hash_or_file)).result).to_hash
      hash = hash[self.class.namespace] if self.class.namespace
      self.update hash
    end
  end
  
  module NodeDefinder

    def singleton(obj)
      class << obj; self; end
    end

    private

    def method_missing(name, *args, &block)
      if key?(name.to_s)
        define_method_for_node_or_leaf name
      else
        super
      end
    end

    def define_method_for_node_or_leaf(name)
      if self[name.to_s].is_a? Hash
        node = self[name.to_s]
        node.extend NodeDefinder
        singleton(self).send(:define_method, name) { node }
        node
      else
        leaf = self[name.to_s]
        singleton(self).send(:define_method, name) { leaf }
        leaf
      end
    end
  end

  include NodeDefinder
end
