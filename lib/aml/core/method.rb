class Core

	@words = %w[a ac accumsan adipiscing aenean aliquam aliquet amet ante arcu at auctor augue bibendum blandit commodo condimentum congue consectetur consequat convallis cras curabitur cursus dapibus diam dictum dictumst dignissim dis dolor donec dui duis egestas eget eleifend elementum elit enim erat eros est et etiam eu euismod facilisi facilisis fames faucibus felis fermentum feugiat fringilla fusce gravida habitasse hac hendrerit iaculis id imperdiet in integer interdum ipsum justo lacinia lacus laoreet lectus leo libero ligula lobortis lorem luctus maecenas magna magnis malesuada massa mattis mauris metus mi molestie mollis montes morbi mus nam nascetur natoque nec neque nibh nisi nisl non nulla nullam nunc odio orci ornare parturient pellentesque penatibus pharetra phasellus placerat platea porta porttitor posuere potenti praesent pretium primis proin pulvinar purus quam quis quisque rhoncus ridiculus risus rutrum sagittis sapien scelerisque sed sem semper sit sociis sodales sollicitudin suscipit suspendisse tellus tempor tempus tincidunt tortor tristique turpis ullamcorper ultrices ultricies urna ut varius vehicula vel velit venenatis vestibulum vitae vivamus viverra volutpat vulputate]

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

	def self.lorem(index=0, a={}, d={:number=>5,:type=>'paragraph',:capitalize=>true})
		#(en-us)
		a = d.merge(a)
		a[:number] = a[:number].to_i
		string = ""
		if a[:type] == 'paragraph'
			string = self._random_paragraph(a[:number])
		elsif a[:type] == 'sentence'
			string = self._random_sentence(a[:number])
		elsif a[:type] == 'title'
			for i in 1..rand(a[:number]-1)+1
				string += self._random_word(a[:capitalize]) + " "
			end
			string.strip!
		elsif a[:type] == 'word'
			string = self._random_word(a[:capitalize])
		elsif a[:type] == 'name'
			string = self._random_word(true) + ' ' + self._random_word(a[:capitalize])[0] + '. ' + self._random_word(true)
		elsif a[:type] == 'address'
			address = []
			count = rand(2)+2
			until address.count == count do
				address << self._random_word(true)
			end
			city = []
			count = rand(1)+1
			until city.count == count do
				city << self._random_word(true)
			end
			string = (rand(5000)+100).to_s + ' ' + address.join(' ') + ', ' + city.join(' ') + ', ' + self._random_word(a[:capitalize])[0] +  self._random_word(a[:capitalize])[0] + ' ' + rand(10000...99999).to_s
		elsif a[:type] == 'phone'
			string = '('+ rand(100...999).to_s + ') ' + rand(100...999).to_s + '-' + rand(1000...9999).to_s
		end
		return string
	end

	def self._random_word(capitalize=false)
		string = @words[rand(@words.count)]
		string = string.capitalize if capitalize
		string
	end

	def self._random_sentence(max_words=20)
		count = rand(max_words)+3
		count = max_words if count > max_words
		string = []
		until string.count == count do
			string << self._random_word(string.count==0)
		end
		string.join(' ') + '.'
	end

	def self._random_paragraph(max_sentences=10)
		count = rand(max_sentences)+3
		count = max_sentences if count > max_sentences
		string = []
		until string.count == count do
			string << self._random_sentence
		end
		string.join(' ')
	end

end