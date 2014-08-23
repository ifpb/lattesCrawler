require 'nokogiri'
require 'open-uri'
require 'json'
require './util.rb'

file = File.read('../data/pos.json').sub('var pos = ', '')
pos = JSON.parse(file)

puts "\n\n\n######\nIniciando o crawler\n\n"

researchers = {}
threadsResearch = []

[
	'28001010095P3', #UFBA 6 lattes undefined
	'22003010018P1', #UECE ok
	'22008012004P2', #IFCE ok
	'52001016027P2', #UFG lattes undefined Leslie Richard Foulds, colaboradores
	'20001010022P0', #UFMA 4 nomes errados
	'32002017027P2', #UFV ok    TODO (colaborador, permantente)
	'32004010027P9', #UFLA ok
	'32005016034P8', #UFJF ok
	# '28001010061P1', #UFBA
].each do |idProgram|
	researchers[idProgram] = {}
	info = pos[idProgram]
	puts "\n######\n"+info.values[0..2].join(' ')+"\n"
	
	# TODO Try SocketError
	threadsResearch << Thread.new do
		
		doc = Nokogiri::HTML(open(info['researchers']))

		fields = {}
		info['crawlerSchema'].each do |field|
			fields[field[0]] = doc.css(field[1])
			if field[0] == 'names'
				fields['names'] = drop_empty_names(fields['names'])
			end
		end	

		# fields['names'].each_with_index do |name, index|
		# 	researcher = {}
		# 	puts "\n==="
		# 	threadsField = []
			
		# 	# TODO id research form lattes
		# 	info['crawlerSchema'].keys.each do |field|
		# 		if(field != 'embedded')
		# 			researcher[field] = get_field(field, fields[field][index])
		# 			puts researcher[field]
		# 		else
		# 			# Open researcher homepage
		# 			# TODO Thread
		# 			threadsField << Thread.new do
		# 				homepage = Nokogiri::HTML(open(get_url(info['homepage'])+name[:href]))
		# 				info['crawlerSchema']['embedded'].each do |field|
		# 					if(homepage.css(field[1]).size != 0)
		# 						researcher[field[0]] = get_field(field[0], homepage.css(field[1])[0])
		# 					else
		# 						researcher[field[0]] = 'undefined'
		# 					end
		# 					puts researcher[field[0]]
		# 				end	
		# 			end
		# 		end
		# 	end
		# 	threadsField.each do |t|
		# 		t.join
		# 	end

		# 	idResearch = extract_id_lattes(researcher['lattes'])
		# 	researchers[idProgram][idResearch] = researcher
		# end
	end
	threadsResearch.each do |t|
		t.join
	end
	# puts researchers[idProgram]
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