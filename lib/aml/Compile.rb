class Compile
	require "aml/Prepare"
	def initialize(argument)
		@argument = argument
		file = @argument.get('build')
		@prepare = Prepare.new(file)
		@inline = [
			{:type=> :attribute, :regex=> /@\(\:(?<name>[\w|\-]+)\)/},
			{:type=> :method, :regex=> /::((?<bundle>[\w|\-]+)\.)?(?<name>[\w|\-]+)(\{(?<attribute>.+)\})?/},
			{:type=> :variable, :regex=> /\@\(((?<bundle>[\w|\-]+)\.)?(?<name>[\w|\-]+)\)/}
		]
		@prepare.cluster.variables['false'] = {} if @prepare.cluster.variables.include?('false') == false
		local = [
			{:name=> 'file-created', :value=> Time.new.strftime('%Y-%m-%d %H:%M:%S')},
			{:name=> 'file-name', :value=> File.basename(file)},
			{:name=> 'file-path', :value=> File.expand_path(file)}
		].each do |variable|
			@prepare.cluster.variables['false'][variable[:name].to_s] = [{:number=>0, :value=>variable[:value].to_s}]
		end

		@log = []

		@prepare.log.each do |log|
			if log[:type] == "mixin"
				@log << log if log[:bundle] != false
			else
				@log << log
			end
		end
		

		if @log.count == 0
			process
			@prepare.cluster.post_process
		end

	end
	def log
		@log
	end
	def structure
		@prepare.cluster.definition.select{|k|k.self[:type] == "base"}.first.self[:hash]
	end
	def process
		@prepare.cluster.definition.each do |definition|
			definition.self[:hash].each_with_index do |line, index|
				process_variable_and_method(line, index, definition)
				process_mixin(line, index, definition)
				process_partial(line, index, definition)
			end
		end
		process if @prepare.cluster.definition.select{|k|k.self[:type] == "base"}.first.self[:hash].select{|k|k[:type] == :mixin or k[:type] == :partial}.count > 0
	end
	def post_process
		@prepare.cluster.definition.each do |definition|
			definition.self[:hash].each_with_index do |line, index|
				process_variable_and_method(line, index, definition, true)
			end
		end
	end
	private
	def has_match?(string, regex)
		return string.to_s.match(regex) != nil
	end
	def process_variable_and_method(line, index, definition,  methods=false)
		definition.self[:hash][index] = process_variable_line(line, definition)
		definition.self[:hash][index] = process_method_line(line, definition) if methods
	end

	def recursive_attribute_replace_variable(attributes, line, definition)
		attributes.each do |attribute, value|
			if value.is_a? Hash
				value = recursive_attribute_replace_variable(value, line, definition)
			else
				value = process_variable_find(value.to_s, line, definition)
			end
			attributes[attribute] = value
		end
		attributes
	end

	def process_variable_line(line, definition)
		if line[:type] == :string
			line[:value] = process_variable_find(line[:value], line, definition)
			parse = Parse.new(definition.self[:bundle])
			line = parse.line("#{"\t" * line[:index]}#{line[:value]}",line[:number])
		else
			line[:text] = process_variable_find(line[:text], line, definition)
			line[:value] = process_variable_find(line[:value], line, definition)
			if line.key? :attribute and line[:attribute].count > 0
				line[:attribute] = recursive_attribute_replace_variable(line[:attribute], line, definition)
			end
		end
		line
	end

	def recursive_attribute_replace_method(attributes, line)
		attributes.each do |attribute, value|
			if value.is_a? Hash
				value = recursive_attribute_replace_method(value, line)
			else
				value = process_method_find(value.to_s, line)
			end
			attributes[attribute] = value
		end
		attributes
	end

	def process_method_line(line, definition)
		if line[:type] == :string
			line[:value] = process_method_find(line[:value], line)
			parse = Parse.new(definition.self[:bundle])
			line = parse.line("#{"\t" * line[:index]}#{line[:value]}",line[:number])
		else
			line[:text] = process_method_find(line[:text], line)
			if line.key? :attribute and line[:attribute].count > 0
				line[:attribute] = recursive_attribute_replace_method(line[:attribute],line)
			end
		end
		line
	end
	def process_variable_find(string, line, definition)
		regex = @inline.select{|k|k[:type] == :variable}[0][:regex]
		string = string.to_s.gsub(regex).each do
			process_variable_replace($1, $2, line[:number], definition)
		end
 		string = process_variable_find(string, line, definition) if has_match?(string, regex)
		return string
	end
	def process_method_find(string, line)
		regex = @inline.select{|k|k[:type] == :method}[0][:regex]
		string = string.to_s.gsub(regex).each do
			process_method_replace($1, $2, $3, line[:index])
		end
 		string = process_method_find(string, line) if has_match?(string, regex)
		return string
	end
	def process_variable_replace(bundle, name, number, definition)
		bundle = false.to_s if bundle == nil
		number = 0 if bundle != "false"
		begin
			@prepare.cluster.variables.reject{|k| k != bundle}.first.last.reject{|k| k != name}.first.last.select{|k| if number != 0 then k[:number] < number else k[:number] == k[:number] end}.last[:value]
		rescue
			@log << {:fail=>false, :file=>definition.self[:file], :bundle=>definition.self[:bundle], :line=>number, :message=>"#{bundle.to_s != false.to_s ? bundle+"." : nil}#{name} variable does not exist; ignored."}
			return nil
		end
	end
	def process_method_replace(bundle, name, attribute, index)
		bundle = 'core' if bundle == nil
		begin
			file = bundle == 'core' ? File.join(File.dirname(File.expand_path(__FILE__)),'core','method.rb') : File.join(File.dirname(File.expand_path(definition.self[:file])),line[:bundle],'method.rb')
			Compile.class_eval File.read(file)
			method_attribute = Line.new(bundle, :string, @inline.select{|k|k[:type] == :method}[0][:regex])
			method_attribute = method_attribute.match?("::#{bundle}.#{name}{#{attribute}}", index)
			attribute = method_attribute[:attribute]
			Compile.const_get(bundle.split('-').map{|k|k.capitalize}.join).method(name).call(index, attribute)
		rescue
			return nil
		end
	end
	def process_mixin(line, index, definition)
		if line[:type] == :mixin
			definition.self[:hash].delete_at index
			mixin = process_mixin_find(line, line[:index], definition)
			if mixin.is_a? Hash
				mixin[:structure].each_with_index do |mixin_line, mixin_index|
					definition.self[:hash].insert(index+mixin_index, mixin_line)
				end
			else
				@log << {:fail=>false, :file=>definition.self[:file], :bundle=>definition.self[:bundle], :line=>line[:number], :message=>"#{line[:bundle] ? line[:bundle]+ '.' : nil}#{line[:name]} mixin does not exist; ignored."}
			end
		end
	end
	def process_mixin_find(line, offset=0, definition)
		begin
			mixin = Marshal.load(Marshal.dump(@prepare.cluster.mixins.reject{|k|k != line[:bundle].to_s}.first.last.reject{|k|k != line[:name]}.first.last))
			mixin[:attribute] = mixin[:attribute].merge(line[:attribute])
			mixin[:attribute].each do |attribute, value|
				mixin[:attribute][attribute] = process_variable_find(value, line, definition)
			end
			mixin[:structure].each do |mixin_line|
				mixin_line[:index] += offset
				mixin_line[:number] = line[:number]
				mixin_line = process_attribute(mixin_line, mixin)
				mixin_line = process_variable_line(mixin_line, definition)
			end
			return mixin
		rescue
			return false
		end
	end

	def recursive_attribute_replace_attribute(attributes, mixin)
		attributes.each do |attribute, value|
			if value.is_a? Hash
				value = recursive_attribute_replace_attribute(value, mixin)
			else
				value = process_attribute_find(value.to_s, mixin)
			end
			attributes[attribute] = value
		end
		attributes
	end

	def process_attribute(line, mixin)
		if line[:type] == :string
			line[:value] = process_attribute_find(line[:value], mixin[:attribute])
		else
			line[:text] = process_attribute_find(line[:text], mixin[:attribute])
			if line[:attribute] != nil
				line[:attribute] = recursive_attribute_replace_attribute(line[:attribute],mixin[:attribute])
			end
		end
		line
	end

	def process_attribute_find(string, attribute)
		regex = @inline.select{|k|k[:type] == :attribute}[0][:regex]
		string = string.to_s.gsub(regex).each do
			attribute[$1.to_sym].to_s
		end
		string = process_attribute_find(string,attribute) if has_match?(string, regex)
		return string
	end
	def process_partial(line, index, definition)
		if line[:type] == :partial
			definition.self[:hash].delete_at index
			partial = process_partial_find(line, line[:index], definition)
			if partial.is_a? Array
				partial.each_with_index do |partial_line,partial_index|
					definition.self[:hash].insert(index+partial_index,partial_line)
				end
			end
		end
	end
	def process_partial_find(line, offset, definition)
		path = line[:bundle].to_s == false.to_s ? "partial" : line[:bundle].to_s
		partial_number = line[:number]
		patrial_attribute = line[:attribute]
		partial = Definition.new(File.join(@argument.get('path'),path,line[:name]+'.aml'), line[:type].to_s, line[:bundle])
		partial.self[:hash].each_with_index do |line, index|
			line[:number] = partial_number
			line = process_attribute(line, {:attribute=>patrial_attribute}) if patrial_attribute.count > 0
			line = process_variable_line(line, definition)
		end
		partial.self[:hash].each do|line|
			line[:index] += offset
		end
		partial.self[:hash]
	end
end