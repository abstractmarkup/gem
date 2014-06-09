class Definition
	require "aml/Parse"
	def initialize(file, type, bundle=false)
		@log = []
		@definition = {}
		@definition[:file] = file
		@definition[:type] = type
		@definition[:bundle] = bundle
		@definition[:hash] = []
		@definition[:variable] = {}
		@definition[:mixin] = {}
		number = 0
		begin
			parse = Parse.new(bundle)
			# Remove Comment Line(s)
			File.open(file).read.gsub(/%!--[^%]*--%$/,'').each_line do |line|
				number+=1
				# Remove Empty Lines
				add_line(parse.line(line,number))
			end
			process_variable_definition
			process_mixin_definition
			
		rescue Exception => e
			@log << {:fail=>true, :file=>@definition[:file], :type=>@definition[:type], :bundle=> bundle, :message=>'file does not exist.'}
			false
		end
	end
	def log
		@log
	end
	def self
		@definition
	end
	private
	def add_line(line)
		@definition[:hash] << line if line[:type] != :empty
	end
	# Process Variable Definition (Local)
	def process_variable_definition
		@definition[:hash].reject{|k,v| k[:type] != :variable_definition}.each do |variable|
			variable[:bundle] = variable[:bundle].to_s
			@definition[:variable][variable[:bundle]] = {} if @definition[:variable].has_key?(variable[:bundle]) == false
			@definition[:variable][variable[:bundle]][variable[:name]] = {} if @definition[:variable][variable[:bundle]].has_key?(variable[:name]) == false
			@definition[:variable][variable[:bundle]][variable[:name]][variable[:number]] = variable[:value]
		end
		@definition[:hash] = @definition[:hash].reject{|k,v| k[:type] == :variable_definition}
	end
	# Process Mixin Definition (Local)
	def process_mixin_definition
		mixin_definition = @definition[:hash].reject{|k|k[:type] != :mixin_definition}
		mixin_definition_end = @definition[:hash].reject{|k|k[:type] != :mixin_end}
		if mixin_definition.count == mixin_definition_end.count
			mixin_definition.each_with_index do |mixin,index|
				@definition[:mixin][@definition[:bundle]] = {} if @definition[:mixin].has_key?(@definition[:bundle]) == false
				if @definition[:mixin][@definition[:bundle]].has_key?(mixin[:name]) == false
					@definition[:mixin][@definition[:bundle]][mixin[:name]] = {
						:attribute => mixin[:attribute],
						:structure => @definition[:hash].reject{|k,v| k[:number].between?(mixin[:number]+1,mixin_definition_end[index][:number]-1) == false}
					}
					@definition[:mixin][@definition[:bundle]][mixin[:name]][:structure].each do |line|
						line[:index]-=1
					end
				else
					@log << {:fail=>false, :file=>@definition[:file], :bundle=>@definition[:bundle], :line=>mixin[:number], :message=>"#{mixin[:name]} duplicate mixin definition; ignored."}
				end
				@definition[:hash] = @definition[:hash].reject{|k,v| k[:number].between?(mixin[:number],mixin_definition_end[index][:number])}
			end
		end
	end
end