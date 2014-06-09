# Convert a string input to a Hash output.
class Line
	# Create a new Line with a symbol type and regular expression.
	def initialize(bundle, type, regex)
		@line = {}
		@line[:type] = type
		@line[:regex] = regex
		@line[:bundle] = bundle
	end
	# Return a Hash if the line match is successful, otherwise false.
	def match?(string,number)
		match = string.match(@line[:regex])
		match ? process_match(match,number) : false
	end
	private
	# Return a processed Hash based on the matches and convert keys to symbols.
	def process_match(match,number)
		line = Hash[match.names.zip(match.captures)]
		line = Hash[line.map{|(k,v)| [k.to_sym,v]}]
		line[:type] = @line[:type]
		line[:index] = match[0].match(/^\t{0,}/).to_s.length
		line[:number] = number
		line[:name] = 'div' and line[:type] = :tag if line[:type] == :tag_shorthand
		# attribute value to Hash
		line[:attribute] = recursive_string_to_hash(line[:attribute]) if line.key? :attribute
		# key values to String
		%w[bundle class name text value id_first id_last reset].each do |key|
			line[key.to_sym] = line[key.to_sym].to_s if line.key? key.to_sym
		end
		# key values to String.Strip!
		%w[text].each do |key|
			line[key.to_sym] = line[key.to_sym].strip! if line.key? key.to_sym
		end
		# bundle
		line[:bundle] = @line[:bundle] if line.key? :bundle and line[:bundle].to_s.length == 0
		if line[:type] == :mixin
			line[:bundle] = 'core' and line[:name] = line[:name][1..-1]  if line[:name][0] == '.'
		elsif line[:type] == :method
			line[:bundle] = 'core' if line[:bundle] == false
		end
		# class
		if line.key? :class
			line[:class] = '.' + line[:class]
			line[:attribute][:class] = line[:class].split('.').join(' ').strip!
			line.delete(:class)
		end
		# close 
		line[:close] = %w(tag self none)[line[:close].to_s.length].to_sym if line.key? :close
		# id
		if line.key? :id_first and line[:id_first].length > 0
			line[:attribute][:id] = line[:id_first]
		elsif line.key? :id_last and line[:id_last].length > 0
			line[:attribute][:id] = line[:id_last]
		end
		line.delete(:id_first) if line.key? :id_first
		line.delete(:id_last) if line.key? :id_last
		# reset
		line[:reset] = line[:reset].to_s.length == 0 ? false : true if line.key? :reset
		# return sorted Hash
		Hash[line.sort]
	end
	# Return the Hash equivalent of a given String (no evaluation).
	def recursive_string_to_hash(string)
		hash = {}
		regex = /:(?<name>\w+)\s?=>\s?(?<hash>{(.+?)?}|(?<quote>'|")(?<value>.+?)??\k<quote>)/
		names = regex.names
		if string != nil
			string.scan(regex){|match|
				thisHash = Hash[names.zip(match)]
				if thisHash["hash"].to_s[0] == "{"
					hash[thisHash["name"].to_sym] = recursive_string_to_hash(thisHash["hash"])
				else
					hash[thisHash["name"].to_sym] = thisHash["value"].to_s.strip
				end
			}
		end
		# return sorted Hash
		Hash[hash.sort]
	end
end