class Core

	@words = %w[a ac accumsan adipiscing aenean aliquam aliquet amet ante arcu at auctor augue bibendum blandit commodo condimentum congue consectetur consequat convallis cras curabitur cursus dapibus diam dictum dictumst dignissim dis dolor donec dui duis egestas eget eleifend elementum elit enim erat eros est et etiam eu euismod facilisi facilisis fames faucibus felis fermentum feugiat fringilla fusce gravida habitasse hac hendrerit iaculis id imperdiet in integer interdum ipsum justo lacinia lacus laoreet lectus leo libero ligula lobortis lorem luctus maecenas magna magnis malesuada massa mattis mauris metus mi molestie mollis montes morbi mus nam nascetur natoque nec neque nibh nisi nisl non nulla nullam nunc odio orci ornare parturient pellentesque penatibus pharetra phasellus placerat platea porta porttitor posuere potenti praesent pretium primis proin pulvinar purus quam quis quisque rhoncus risus rutrum sagittis sapien scelerisque sed sem semper sit sociis sodales sollicitudin suscipit suspendisse tellus tempor tempus tincidunt tortor tristique turpis ullamcorper ultrices ultricies urna ut varius vehicula vel velit venenatis vestibulum vitae vivamus viverra volutpat vulputate werumensium xiphias]

	def self.rand(index=0, a={}, d={:min=>'1', :max=>'10'})
		offset = 1 if a[:min] == 0
		return rand(a[:max]+offset)+a[:min]
	end

	def self.date(index=0, a={}, d={:format=>'%Y-%m-%d %H:%M:%S'})
		a = d.merge(a)
		time = Time.new
		return time.strftime(a[:format])
	end

	def self.copyright(index=0, a={}, d={:name=>false})
		a = d.merge(a)
		return '&copy; ' + self.year + ' ' + a[:name]
	end

	def self.alphanumeric(index=0, a={}, d={:string=>nil})
		a = d.merge(a)
		return a[:string].downcase.gsub(/[^a-zA-Z0-9]/,'-')
	end

	def self.year(index=0, a={})
		return self.date(index,{:format=>'%Y'})
	end

	def self.lorem(index=0, a={}, d={:paragraphs=>6, :words=>8, :type=>'paragraph',:capitalize=>true})
		#Generate random copy based on en-us formats.
		a = d.merge(a)
		a[:paragraphs] = a[:paragraphs].to_i
		a[:words] = a[:words].to_i
		string = ""
		if a[:type] == 'word'
			string = self._random_word(a[:capitalize])
		elsif a[:type] == 'sentence'
			string = self._random_sentence(a[:words])
		elsif a[:type] == 'paragraph'
			string = self._random_paragraph(a[:paragraphs], a[:words])
		elsif a[:type] == 'title'
			string = self._random_title(a[:words])
		elsif a[:type] == 'name'
			string = self._random_name
		elsif a[:type] == 'address'
			string = self._random_address
		elsif a[:type] == 'phone'
			string = self._random_phone
		elsif a[:type] == 'email'
			string = self._random_email
		end
		return string
	end

	def self._random_word(capitalize=false)
		string = @words[rand(@words.count)]
		string = string.capitalize if capitalize
		string
	end

	def self._random_sentence(number)
		words = rand(number)
		words = number if words == 0
		words = words <= (number/2) ? number/2+rand(0..1) : words
		string = []
		until string.count == words do
			string << self._random_word(string.count==0)
		end
		string.join(' ') + '.'
	end

	def self._random_paragraph(number, words)
		paragraphs = rand(number)
		paragraphs = number if paragraphs == 0
		paragraphs = paragraphs <= (number/2) ? number/2+rand(0..1) : paragraphs
		string = []
		until string.count == paragraphs do
			string << self._random_sentence(words)
		end
		string.join(' ')
	end

	def self._random_title(number)
		words = rand(number)
		words = number if words == 0
		words = words <= (number/2) ? number/2+rand(0..1) : words
		string = []
		until string.count == words do
			string << self._random_word(true)
		end
		string.join(' ')
	end

	def self._random_name
		self._random_word(true) + ' ' + self._random_word(true)[0] + '. ' + self._random_word(true)
	end

	def self._random_phone
		'('+ rand(100...999).to_s + ') ' + rand(100...999).to_s + '-' + rand(1000...9999).to_s
	end

	def self._random_address
		address = []
		count = rand(2..4)
		until address.count == count do
			address << self._random_word(true)
		end
		city = []
		count = rand(1..2)
		until city.count == count do
			city << self._random_word(true)
		end
		rand(100..5000).to_s + ' ' + address.join(' ') + ', ' + city.join(' ') + ', ' + self._random_word(true)[0].upcase + self._random_word(true)[0].upcase + ' ' + rand(10000...99999).to_s
	end

	def self._random_email
		self._random_word + '@' + self._random_word + '.' + self._random_word[0..3]
	end

end