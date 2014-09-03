require 'nokogiri'
require 'open-uri'

urls = [
	'http://www.ifpb.edu.br/',
	'http://www.google.com/',
	'http://www.ufpb.br/',
	'http://www.minhaconexao.com.br/',
	'http://g1.globo.com/index.html'
]


def job(url, index)
	urls2 = [
		'http://www.ifce.edu.br/',
		'http://www.ifrn.edu.br/'
	]
	doc = Nokogiri::HTML(open(url))
	puts url+' '+index.to_s+' '+doc.css('a').length.to_s
	if([2,4].include? index)
		threads = []
		urls2.each_with_index { |url, indexLocal|
			threads << Thread.new {
				puts index
				job(url, indexLocal)
			}
		}
		threads.each {|t| t.join}
	end
end

threads = []
urls.each_with_index { |url, index|
	threads << Thread.new {
		job(url, index)
	}
}
threads.each {|t| t.join}