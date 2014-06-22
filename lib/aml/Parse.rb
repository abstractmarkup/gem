class Parse
	require "aml/Line"
	def initialize(bundle=false)
		@line = []
		@line << Line.new(bundle, :variable_definition, /^(\s{1,})?\@((?<bundle>[\w|\-]+)\.)?(?<name>[\w|\-]+)\s?(\=)\s?(?<value>.+)?$/)
		@line << Line.new(bundle, :mixin, /^(\s{1,})?%\(((?<bundle>[\w|\-]+)\.)?(?<name>[^~][\w|\-]+)\)(\{(?<attribute>.+)\})?[^\{]?/)
		@line << Line.new(bundle, :mixin_definition, /^%%(?<name>[\w|\-]+)(\((?<attribute>.+?)\))?{/)
		@line << Line.new(bundle, :mixin_end, /^\}$/)
		@line << Line.new(bundle, :partial, /^(\s{1,})?%\(\~((?<bundle>[\w|\-]+)\.)?(?<name>[\w|\-]+)\)(\{(?<attribute>.+)\}[^\{]?)?$/)
		@line << Line.new(bundle, :tag, /^(\s{1,})?(?<!%)%(?<close>\/{0,2})?(?<name>[\w|\-]+)(\#(?<id_first>[\w|\-]+))?(\.(?<class>[\w|\-|\.]+))?(\#(?<id_last>[\w|\-]+))?(?<reset>\*{1,})?(\{(?<attribute>.+)\})?(?<text>.+)?$/)
		@line << Line.new(bundle, :tag_shorthand, /^(\s{1,})?(?=[#|\.|\/])(\#(?<id_first>[\w|\-]+))?(\.(?<class>[\w|\-|\.]+))?(\#(?<id_last>[\w|\-]+))?(?<reset>\*{1,})?(?<close>\/{0,2})?(\{(?<attribute>.+)\})?(?<text>.+)?$/)
		@line << Line.new(bundle, :conditional, /^(\s{1,})?-\s?(?<name>if|loop|end)(\s(?<value>.+))?$/)
		@line << Line.new(bundle, :empty, /^$/)
		@line << Line.new(bundle, :eval, /^(\s{1,})?==(\s{1,})(?<value>.+)?/)
		@line << Line.new(bundle, :string, /(\s{1,})?(?<value>.+)?/)
	end
	# Return the line as a Hash.
	def line(string,number)
		@line.each do |type|
			line = type.match?(string,number)
			return line if line
		end
	end
end