require 'nokogiri'
require 'open-uri'
require 'json'
require './util.rb'

file = File.read('../data/pos.json').sub('var pos = ', '')
pos = JSON.parse(file)

puts "\n\n\n######\nIniciando o crawler\n\n"

researchers = {}

#28001010095P3-UFBA
# info = pos[0]
# puts '#'+info.values[0..2].join(' ')
# researchers[info['idProgram']] = []
# doc = Nokogiri::HTML(open(info['researchers']))
# doc.css(info['crawlerSchema']['names']).each do |link|
# 	researcher = {}
# 	researcher[:name] = link.content
# 	puts researcher[:name]
# 	# Open researcher homepage
# 	homepage = Nokogiri::HTML(open(info['crawlerSchema']['domain']+link['href']))
# 	homepage.css(info['crawlerSchema']['image']).each do |image|
# 		researcher[:image] = image['src']
# 	end
# 	lattesLink = homepage.css(info['crawlerSchema']['lattes'])
# 	if(lattesLink.size != 0)
# 		lattesLink.each do |lattes|
# 			researcher[:lattes] = lattes['href']
# 		end
# 	else
# 		researcher[:lattes] = 'undefined'
# 	end
# 	researchers[info['idProgram']] << researcher
# end

# puts researchers.to_json

#22003010018P1-UECE
#22008012004P2-IFCE
# [1,2].each do |num|
# 	info = pos[num]
# 	puts
# 	puts
# 	puts '#'+info.values[0..2].join(' ')
# 	puts
# 	researchers[info['idProgram']] = []
# 	doc = Nokogiri::HTML(open(info['researchers']))

# 	names = doc.css(info['crawlerSchema']['names'])
# 	lattes = doc.css(info['crawlerSchema']['lattes'])

# 	names.each_with_index do |name, index|
# 		researcher = {}
# 		researcher[:names] = names[index].content.strip
# 		puts researcher[:names]
# 		researcher[:lattes] = lattes[index][:href]
# 		researchers[info['idProgram']] << researcher
# 	end 
# 	# puts researchers[info['idProgram']]
# end
# puts researchers.to_json

#28001010095P3-UFBA
#22003010018P1-UECE
#22008012004P2-IFCE
#52001016027P2-UFG
(0..3).each do |num|
	info = pos[num]
	puts "\n######\n"+info.values[0..2].join(' ')+"\n"
	researchers[info['idProgram']] = []
	doc = Nokogiri::HTML(open(info['researchers']))

	fields = {}
	info['crawlerSchema'].each do |field|
		fields[field[0]] = doc.css(field[1])	
	end

	fields['names'].each_with_index do |name, index|
		researcher = {}
		puts "\n==="
		
		info['crawlerSchema'].keys.each do |field|
			if(field != 'embedded')
				researcher[field] = get_field(field, fields[field][index])
				puts researcher[field]
			else
				# Open researcher homepage
				# TODO Thread
				homepage = Nokogiri::HTML(open(get_url(info['homepage'])+name[:href]))
				info['crawlerSchema']['embedded'].each do |field|
					if(homepage.css(field[1]).size != 0)
						researcher[field[0]] = get_field(field[0], homepage.css(field[1])[0])
					else
						researcher[field[0]] = 'undefined'
					end
					puts researcher[field[0]]
				end	
			end
		end

		researchers[info['idProgram']] << researcher
	end
	# puts researchers[info['idProgram']]
end
# puts researchers.to_json
puts "\n\n######\nGerando o arquivo lattes.json"
file = File.open("lattes.json", "w")
file.write(JSON.pretty_generate(researchers))



#28001010061P1-UFBA TODO
# info = pos[0]
# doc = Nokogiri::HTML(open('http://wiki.dcc.ufba.br/PMCC/CorpoDocente'))
# doc.css('table#tableCorpoDocente1 tr td a:nth-child(1)').each do |link|
# 	puts link.content
# 	puts 'image'
# 	homepage = Nokogiri::HTML(open('http://wiki.dcc.ufba.br'+link['href']))
# 	homepage.css('div#content > ul:last-of-type > li:contains("cv") > a:first-of-type').each do |lattes|
# 		puts lattes['href'] 
# 	end  
# end