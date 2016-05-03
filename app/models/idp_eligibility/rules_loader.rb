require 'yaml'

module IdpEligibility
  class RulesLoader
    attr_reader :recommended_rules
    attr_reader :non_recommended_rules
    def initialize(rules_path)
      @rules_path = rules_path
    end

    def load
      recommended_rules = load_rules("recommended_rules")
      non_recommended_rules = load_rules("non_recommended_rules")
      all_rules = merge_rules(recommended_rules, non_recommended_rules)
      RulesRepository.new(recommended_rules, non_recommended_rules, all_rules)
    end

    RulesRepository = Struct.new(:recommended_rules, :non_recommended_rules, :all_rules)

  private

    def load_rules(type)
      rules_files = File.join(@rules_path, '*.yml')
      Dir::glob(rules_files).inject({}) do |rules, file|
        yaml = YAML::load_file(file)
        idp_rules = yaml.fetch(type)
        yaml.fetch('simpleIds').each do |simple_id|
          rules[simple_id] = idp_rules.map { |rule| rule.map(&:to_sym) }
        end
        rules
      end
    end

    def merge_rules(left_rules, right_rules)
      left_rules.merge(right_rules) do |_key, left, right|
        left + right
      end
    end
  end
end
