# Entry Point for Abstract Markup Language
class AbstractMarkupLanguage
	require "aml/Build"
	def initialize(argument)
		if ['--v', '--version', 'version'].include? argument.downcase
			puts Gem.loaded_specs['aml'].version.to_s
		else
			@build = Build.new(argument)
		end
	end
end