class Prepare
	require "aml/Cluster"
	def initialize(file)
		@log = []
		@cluster = false
		@file = []
		@watch = []
		# Load Core Bundle
		path = File.join(File.dirname(File.expand_path(__FILE__)),'core')
		add_file(File.join(path,'mixin.aml'),'mixin', 'core')
		add_watch(File.join(path,'method.rb'), 'method', 'core')
		# Load Local Bundles
		bundles = Definition.new(file, false)
		bundles.self[:hash].reject{|k|k[:bundle] == false or k[:bundle] == nil}.each do |bundle|
			if @file.select{|k|k[:bundle] == bundle[:bundle]}.count == 0
				path = File.join(File.dirname(file), bundle[:bundle])
				add_file(File.join(path,'mixin.aml'), 'mixin', bundle[:bundle])
				add_watch(File.join(path,'method.rb'), 'method', bundle[:bundle])
				# Load Only Required Partials
				bundles.self[:hash].reject{|k|k[:bundle] != bundle[:bundle]}.reject{|k|k[:type] != :partial}.each do |partial|
					add_file(File.join(path,'partial',partial[:name]+'.aml'), 'partial', bundle[:bundle], bundle[:name])
				end
			end
		end
		# Load Local File Mixin & Method
		path = File.join(File.dirname(file))
		add_file(File.join(path,'mixin.aml'), 'mixin')
		add_watch(File.join(path,'method.rb'), 'method')
		# Load Only Requird Local Partials
		bundles.self[:hash].select{|k|k[:type] == :partial and k[:bundle] == false}.each do |bundle|
			add_file(File.join(path,'partial',bundle[:name]+'.aml'), 'partial', bundle[:bundle], bundle[:name])
		end
		# Load Local File
		add_file(file,'base')
		
		@watch.concat(@file)
		process
	end
	def add_file(file, type, bundle=false, partial=false)
		@file << {:file=>file, :type=> type, :bundle=>bundle, :partial=>partial}
	end
	def add_watch(file, type, bundle=false)
		@watch << {:file=>file, :bundle=>bundle}
	end
	def process
		@cluster = Cluster.new(@file)
		@cluster.process
		@log = cluster.log
	end
	def log
		@log
	end
	def cluster
		@cluster
	end
	def watch
		@watch
	end
end