class Argument
	def initialize(argument={})
		@item = {}
		@item_key = {}
		argument.each do |argument|
			initialize_add(argument)
		end
	end
	def parse(argument)
		arguments = argument.split('--')
		if arguments.count == 1
			arguments = []
			io = argument.split(' ')
			arguments << "build " + io[0] #input file
			if io.count == 2
				arguments << "path " + File.dirname(io[1]) #output path
				arguments << "name " + File.basename(io[1],'.*') #output name
				arguments << "extension " + File.extname(io[1])[1..-1] if io[1].split('.').count > 1 #output extension
			end
		end
		arguments.each do |argument|
			string = argument.split(' ')
			set(string[0], string[1..string.count].join(' ').to_s) if argument.strip.length > 0
		end
	end
	def define(name,value,usage,required=false)
		regex = /\[(?<key>\w)\]/
		keys = []
		name = name.gsub(regex).each do |match|
			match = match.match(regex)[:key]
			keys << match
			match
		end
		@item[name.to_sym] = {
			:value => value,
			:usage => usage,
			:require => required
		}
		@item_key[keys.join.to_sym] = name.to_sym if keys.count > 0
	end
	def set(name, value=nil)
		begin
			@item[_name(name)][:value] = value.to_s
		rescue
		end
	end
	def get(name)
		begin
			@item[_name(name)][:value].to_s
		rescue
		end
	end
	def items
		@item
	end
	def show_help?
		@item.select{|k,v| k == :help and v[:value] != false}.count == 0 ? false : true
	end
	def show_help
		pad = _pad(@item)
		@item.each do |name,data|
			value = data[:value].to_s
			value = nil.to_s if name == :help
			puts "--#{name.to_s.ljust(pad[:name]+1)}\t#{value.ljust(pad[:value]+1)}\t#{data[:usage].ljust(pad[:usage])}"
		end
	end
	def has_requirements?
		@item.select{|k,v| v[:require] == true and v[:value] == nil}.count == 0 ? true : false
	end
	def show_required
		required = @item.select{|k,v| v[:require] == true and v[:value] == nil}
		if required.count == 1
			puts "Please define the --#{required.first.first} argument; #{required.first.last[:usage]}"
		else
			pad = _pad(required)
			required.each do |name,data|
				value = data[:value].to_s
				value = nil.to_s if name == :help
				puts "--#{name.to_s.ljust(pad[:name]+1)}\t#{value.ljust(pad[:value]+1)}\t#{data[:usage].ljust(pad[:usage])}"
			end
		end
	end
	private
	def _name(name)
		if @item.select{|k|k == name.to_sym}.count == 0
			name = @item_key[name.to_sym]
		else
			name = name.to_sym
		end
	end
	def _pad(items)
		pad = {:name=>0,:value=>0,:usage=>0}
		items.each do |name,data|
			pad[:name] = name.to_s.length if name.to_s.length > pad[:name]
			pad[:value] = data[:value].to_s.length if data[:value].to_s.length > pad[:value]
			pad[:usage] = data[:usage].to_s.length if data[:usage].to_s.length > pad[:usage]
		end
		pad
	end
end