# Cluster will have access to all variable and mixin definitions.
class Cluster
	require "aml/Definition"
	def initialize(files)
		@log = []
		@definition = []
		@cluster = {
			:variables => {},
			:mixins => {}
		}
		files.each do |file|
			@definition << Definition.new(file[:file], file[:type], file[:bundle])
		end
	end
	def process
		@definition.each do |definition|
			definition.log.each do |log|
				@log << log
			end
			process_variable_definition(definition)
			process_mixin_definition(definition)
		end
	end
	def post_process
		definition.each do |definition|
			process_conditional(definition)
		end
	end
	def log
		@log
	end
	def variables
		@cluster[:variables]
	end
	def mixins
		@cluster[:mixins]
	end
	def definition
		@definition
	end
	private
	# Process Variable Definition (Cluster)
	def process_variable_definition(definition)
		definition.self[:variable].each do |bundle, variables|
			bundle = bundle.to_s
			@cluster[:variables][bundle] = {} if @cluster[:variables][bundle] == nil
			variables.each do |variable,lines|
				@cluster[:variables][bundle][variable] = [] if @cluster[:variables][bundle][variable] == nil
				lines.each do |number,value|
					@cluster[:variables][bundle][variable] << {:number=>number, :value=>value}
				end
			end
		end
	end
	# Process Mixin Definition (Cluster)
	def process_mixin_definition(definition)
		definition.self[:mixin].each do |bundle, mixins|
			bundle = bundle.to_s
			@cluster[:mixins][bundle] = {} if @cluster[:mixins][bundle] == nil
			mixins.each do |name, mixin|
				mixin[:structure] = process_conditional_block(definition, _get_conditionals(mixin[:structure]),mixin[:structure],'loop')
				@cluster[:mixins][bundle][name] = mixin
			end
		end
	end
	# Process Conditional (Cluster)
	def process_conditional(definition)
		definition.self[:hash] = process_conditional_block(definition, _get_conditionals(definition.self[:hash]), definition.self[:hash], 'loop')
		definition.self[:hash] = process_conditional_block(definition, _get_conditionals(definition.self[:hash]), definition.self[:hash], 'if')
	end

	def recursive_attribute_replace(attributes,find,replace)
		attributes.each do |attribute, value|
			if value.is_a? Hash
				value = recursive_attribute_replace(value,find,replace)
			else
				value = value.to_s.gsub(find,replace)
			end
			attributes[attribute] = value
		end
		attributes
	end

	# Process Conditional Block
	def process_conditional_block(definition, conditionals, lines, type)
		conditional = conditionals.select{|k|k[:name].downcase == type}.sort_by{|k|k[:index]}.reverse
		if conditional.count > 0
			conditional = conditional.first
			conditional_lines = []
			definition_before = lines[0...(conditional[:c_index]-1)]
			definition_after = lines[conditional[:end][:c_index]..lines.count]
			if type == 'loop'
				if is_number?(conditional[:value])
					for i in 1..conditional[:value].to_i
						value = i.to_s
						loop_line = Marshal.load(Marshal.dump(lines.select{|k|k[:c_index] > conditional[:c_index] and k[:c_index] < conditional[:end][:c_index]}))
						loop_line.each do |line|
							line[:index] = line[:index]-1
							[:text,:value].each do |name|
								line[name] = line[name].gsub(/@\(\:index\)/, value) if line[name] != nil
								line[name] = line[name].gsub(/@\(\:zero\-index\)/, ((value.to_i)-1).to_s) if line[name] != nil
							end
							if line[:attribute] != nil
								line[:attribute] = recursive_attribute_replace(line[:attribute],/@\(\:index\)/, value)
								line[:attribute] = recursive_attribute_replace(line[:attribute],/@\(\:zero\-index\)/, ((value.to_i)-1).to_s)
							end
							conditional_lines << line
						end
					end
				else
					conditional[:value].split(',').each_with_index do |value, index|
						value = value.strip
						index = index
						loop_line = Marshal.load(Marshal.dump(lines.select{|k|k[:c_index] > conditional[:c_index] and k[:c_index] < conditional[:end][:c_index]}))
						loop_line.each do |line|
							line[:index] = line[:index]-1
							[:text,:value].each do |name|
								line[name] = line[name].gsub(/@\(\:value\-index\)/, value) if line[name] != nil
								line[name] = line[name].gsub(/@\(\:index\)/, (index+1).to_s) if line[name] != nil
								line[name] = line[name].gsub(/@\(\:zero\-index\)/, index.to_s) if line[name] != nil
							end
							if line[:attribute] != nil
								line[:attribute] = recursive_attribute_replace(line[:attribute],/@\(\:value\-index\)/, value)
								line[:attribute] = recursive_attribute_replace(line[:attribute],/@\(\:index\)/, (index+1).to_s)
								line[:attribute] = recursive_attribute_replace(line[:attribute],/@\(\:zero\-index\)/, index.to_s)
							end
							conditional_lines << line
						end
					end
				end
			elsif type == 'if'
				regex = /(?<a>.+?)\s{1,}?(?<expression>==|!=|>=|<=|>|<|eq|neq|gte|lte|gt|lt)\s{1,}?(?<b>.+)/
				match = conditional[:value].to_s.gsub(regex).each do
					continue = false
					if is_number? $1 and is_number? $3
						if ['=','==','eq'].include?($2.to_s.downcase)
							continue = true if $1.to_i == $3.to_i
						elsif ['!=','neq'].include?($2.to_s.downcase)
							continue = true if $1.to_i != $3.to_i
						elsif ['>=','gte'].include?($2.to_s.downcase)
							continue = true if $1.to_i >= $3.to_i
						elsif ['<=','lte'].include?($2.to_s.downcase)
							continue = true if $1.to_i <= $3.to_i
						elsif ['>','gt'].include?($2.to_s.downcase)
							continue = true if $1.to_i > $3.to_i
						elsif ['<','lt'].include?($2.to_s.downcase)
							continue = true if $1.to_i < $3.to_i
						end
					else
						if ['=','==','eq'].include?($2.to_s.downcase)
							continue = true if $1.to_s == $3.to_s
						elsif ['!=','neq'].include?($2.to_s.downcase)
							continue = true if $1.to_s != $3.to_s
						end
					end
					conditional_lines = Marshal.load(Marshal.dump(lines.select{|k|k[:c_index] > conditional[:c_index] and k[:c_index] < conditional[:end][:c_index]})) if continue
					conditional_lines.each do |line|
						line[:index] = line[:index]-1
					end
				end
			end
			lines = definition_before.concat(conditional_lines).concat(definition_after)
			conditionals = _get_conditionals(lines)
			lines = process_conditional_block(definition,conditionals,lines, type) if conditionals.select{|k|k[:name].downcase == type}.count > 0
		end
		lines
	end

	def is_number?(value)
    	value.to_f.to_s == value.to_s || value.to_i.to_s == value.to_s
  	end

	# Get Conditionals
	def _get_conditionals(lines)
		conditional_line = []
		conditional_block = []
		condition_open = 0
		condition_index = 0
		last_line = false
		lines.each_with_index do |line,index|
			line[:c_index] = index + 1
		end
		lines.select{|k|k[:type] == :conditional}.each do |line|
			if line[:name].downcase != 'end'
				condition_open = condition_open + 1
			else
				condition_open = condition_open - 1
			end
			conditional_block[condition_index] = [] if conditional_block[condition_index] == nil
			conditional_block[condition_index] << line
			condition_index = condition_index + 1 if condition_open == 0
		end
		conditional = []
		conditional_block.each do |block|
			block_open = block.select{|k|k[:name].downcase != 'end'}
			block_close = block.select{|k|k[:name].downcase == 'end'}
			close_block = []
			count = 0
			block_close.each_with_index do |close, index|
				if close_block.count == 0
					close_block << close
				else
					if close_block[index-1][:index] == close[:index]
						close_block.insert(index-1-count, close)
						count += 1
					else
						close_block << close
					end
				end
			end
			close_block = close_block.reverse
			block_open.each_with_index do |line, index|
				line[:end] = {:c_index=>close_block[index][:c_index], :value=> close_block[index][:value]}
				conditional << line
			end
		end
		conditional
	end
end