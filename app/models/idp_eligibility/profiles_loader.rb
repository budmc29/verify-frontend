require 'yaml'
require 'idp_eligibility/attribute_masker'
require 'idp_eligibility/evidence'

module IdpEligibility
  class ProfilesLoader
    attr_reader :recommended_profiles
    attr_reader :non_recommended_profiles
    def initialize(profiles_path)
      @profiles_path = profiles_path
      @document_attribute_masker = AttributeMasker.new(Evidence::DOCUMENT_ATTRIBUTES)
    end

    def load
      recommended_profiles = load_profiles("recommended_profiles")
      non_recommended_profiles = load_profiles("non_recommended_profiles")
      all_profiles = merge_profiles(recommended_profiles, non_recommended_profiles)
      document_profiles = apply_documents_mask(all_profiles)
      GroupedRules.new(
        RulesRepository.new(recommended_profiles),
        RulesRepository.new(non_recommended_profiles),
        RulesRepository.new(all_profiles),
        RulesRepository.new(document_profiles)
      )
    end

    GroupedRules = Struct.new(:recommended_profiles, :non_recommended_profiles, :all_profiles, :document_profiles)

  private

    def apply_documents_mask(profiles)
      @document_attribute_masker.mask(profiles)
    end

    def load_profiles(type)
      profiles_files = File.join(@profiles_path, '*.yml')
      Dir::glob(profiles_files).inject({}) do |profiles, file|
        yaml = YAML::load_file(file)
        idp_profiles = yaml.fetch(type)
        yaml.fetch('simpleIds').each do |simple_id|
          profiles[simple_id] = idp_profiles.map { |profile| Profile.new(profile) }
        end
        profiles
      end
    end

    def merge_profiles(left_profiles, right_profiles)
      left_profiles.merge(right_profiles) do |_key, left, right|
        left + right
      end
    end
  end
end
