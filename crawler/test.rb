require 'nokogiri'
require 'open-uri'

urls = [
	'http://www.ifpb.edu.br/',
	'http://www.google.com/',
	'http://www.ufpb.br/',
	'http://www.minhaconexao.com.br/',
	'http://g1.globo.com/index.html'
]

# def job(url, index)
# 	doc = Nokogiri::HTML(open(url))
# 	puts url+' '+index.to_s+' '+doc.css('a').length.to_s
# end

threads = []
urls.each_with_index { |url, index|
	threads << Thread.new {
		# job(url, index)
		doc = Nokogiri::HTML(open(url))
		puts url+' '+index.to_s+' '+doc.css('a').length.to_s
	}
}
threads.each {|t| t.join}