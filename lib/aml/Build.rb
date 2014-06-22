class Build
	require "aml/Argument"
	require "aml/Compile"
	
	@@structure = []
	@@selfClosing = []

	def initialize(attribute=nil)
		@argument = Argument.new()
		@argument.define('[b]uild', nil, 'input file path and name', true)
		#@argument.define('[w]atch', false, 'watch for build updates')
		@argument.define('[s]elf[c]losing', true, 'enable self closing tags')
		@argument.define('[p]ath', nil, 'output file path')
		@argument.define('[n]ame', nil, 'output file name')
		@argument.define('[e]xtension', 'html', 'output file extension')
		@argument.define('[o]utput', nil, 'output file path and name')
		@argument.define('[h]elp', false, 'list all arguments')
		@argument.parse(attribute)
		if @argument.get('build') != nil.to_s
			@argument.set('path', File.dirname(@argument.get('build'))) if @argument.get('path') == nil.to_s
			@argument.set('name', File.basename(@argument.get('build'),'.*')) if @argument.get('name') == nil.to_s
			if @argument.get('output') == nil.to_s
				@argument.set('output', File.join(@argument.get('path'), @argument.get('name') + '.' + @argument.get('extension')))
			else
				@argument.set('path', File.dirname(@argument.get('output')))
				@argument.set('name', File.basename(@argument.get('output'),'.*'))
				@argument.set('extension', File.extname(@argument.get('output'))[1..-1])
			end
		end

		if @argument.get('selfclosing').to_s.downcase == 'true'
			@@selfClosing = %w[area base basefont bgsound br col frame hr img isindex input keygen link meta param source track wbr]
		elsif @argument.get('selfclosing').to_s.downcase != 'false'
			@@selfClosing = @argument.get('selfclosing').to_s.downcase.split(',')
			@argument.set('selfclosing','custom')
		end

		if @argument.show_help?
			@argument.show_help
		elsif @argument.has_requirements?
			@compile = Compile.new(@argument)
			@compile.process
			@compile.post_process
			if @compile.log.select{|k|k[:fail]==true}.count == 0
				console
				process_complete
			else
				console
			end
		else
			@argument.show_required
		end
	end

	def console
		@compile.log.each do |log|
			line = log[:line] ? ":#{log[:line]}" : ""
			puts "#{log[:file]}#{line} - #{log[:message]}"
		end
	end

	def process_complete
		structure = prepare_structure(prepare_string_line_merge(@compile.structure))
		recursive_merge_lines(structure)
		structure.each do |group|
			recursive_close(group,0,0)
		end
		File.open(@argument.get('output'), 'w'){|file|
			struct_count = @@structure.count-1
			@@structure.each_with_index do |line,index|
				new_line = (index < struct_count) ? $/ : ""
				file.write(line+new_line) if line.strip.length > 0
			end
		}
		puts "Build completed."
	end
	private

	def recursive_close(struct,index=0,index_reset)
		next_index	=	struct.key?(:line) ? index+1 : index
		tab_index	=	"\t" * (index-index_reset)
		opening_tag_attributes = ""
		opening_tag = ""
		closing_tag = ""
		
		#STRING
		if(struct[:line][:type]==:string)
			opening_tag = struct[:line][:value]
		end

		#TAG
		if(struct[:line][:type]==:tag)
			
			struct[:line][:close] = :self if @@selfClosing.include? struct[:line][:name]

			opening_tag_attributes = tag_line_attributes(struct[:line],"")
			opening_tag	=	"<#{struct[:line][:name]}#{opening_tag_attributes}>"
			closing_tag =	"</#{struct[:line][:name]}>"
			if struct.key?(:line)
				if struct[:line][:close] == :self
					opening_tag	=	"<#{struct[:line][:name]}#{opening_tag_attributes} />"
					closing_tag	=	""
				end
				if struct[:line][:close] == :none
					closing_tag	=	""
				end
			end
		end
		tag_text = struct[:line][:text]
		if struct.key?(:children)
			new_line = "\r\n"
			#Tab Reset
			index_reset = struct[:line][:index]+1 if struct[:line][:reset]

			tag_text = "#{new_line}#{tab_index}\t#{tag_text}" if tag_text.to_s.length > 0

			@@structure << "#{tab_index}#{opening_tag}#{tag_text}" if struct.key?(:line)
			struct[:children].each do |struct_children|
				recursive_close(struct_children,next_index,index_reset)
			end

			@@structure << "#{tab_index}#{closing_tag}" if struct.key?(:line)
		else
			@@structure << "#{tab_index}#{opening_tag}#{tag_text}#{closing_tag}"
		end
	end

	def tag_line_attributes(line,base="")
		attributes = hash_to_attribute_build(line[:attribute],"").strip
		attributes = ' ' + attributes if(attributes.length > 0)
	end

	def hash_to_attribute_build(hash,base="")
		hash = hash.sort_by{|key, value| key}
		string = ""
		hash.each do |key, value|
			if(value.is_a?(Hash))
				value.sort_by{|key, value| key}
				string << hash_to_attribute_build(value,"#{base}#{key}-")
			else
				string << "#{base}#{key}=\"#{value}\" " if value.to_s.length > 0
			end
		end
		string
	end

	def prepare_structure(struct,index=0,pstruct={:line=>false,:children=>[]})
		parent_tags = struct.each_index.select{|i| struct[i][:index] == index}.compact
		parent_struct = []
		parent_tags.each_with_index do |struct_index,index|
			last_struct_index = parent_tags.count > index+1 ? parent_tags[index+1]-1 : parent_tags[index]
			last_struct_index = struct.count if(parent_tags.count == index+1)
			parent_struct << struct[struct_index..last_struct_index]
		end
		parent_struct.each do |parent_structure|
			index_struct = {}
			index_struct[:line] = parent_structure[0]
			c = prepare_structure(parent_structure,index+1)
			index_struct[:children] = c if c.count > 0
			pstruct[:children] << index_struct 
		end
		pstruct[:children]
	end

	def recursive_merge_lines(struct,count=0)
	    struct.each_with_index do |group,struct_index|
	        group.each_with_index do |line,gindex|
	            if line.first == :line
	                if line.last[:type] == :string and line.last[:merge]
	                    next_line = struct[struct_index+1].first
	                    if next_line.first == :line and next_line.last[:type] == :string
	                        line.last[:value] += next_line.last[:value]
	                        line.last[:merge] = next_line.last[:merge]
	                        line.last[:merge] = struct_index+1 == struct.count ? false : line.last[:merge]
	                        struct.delete_at struct_index+1
	                    else
	                       line.last[:merge] = false 
	                    end
	                    count +=1 if line.last[:merge]
	                end
	            else
	                recursive_merge_lines(line.last)
	            end
	        end
	    end
	    recursive_merge_lines(struct) if count > 0
	end

	def prepare_string_line_merge(lines)
		regex = /\+\+$/
		lines.each_with_index do |line,index|
			if(line[:type] == :string)
				line[:merge] = line[:value].to_s.match(regex) != nil
				line[:value] = line[:value].to_s.gsub(regex,'') if line[:merge]
			end
		end
		lines
	end


end