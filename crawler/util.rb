require 'uri/http'
require 'cgi'
require 'rest_client'
require 'nokogiri'
require 'open-uri'

# TODO 
# gets_...
# clean names (\r\n\t)
# clean puts

def get_field(field, element)
	# TODO: try dymanic calling
	if(field.include? 'name')
		get_name(element, true)
	elsif(field.include? 'lattes')
		get_lattes(element)
	elsif(field.include? 'image')
		get_image(element)
	elsif(field.include? 'email')
		get_email(element)
	elsif(field.include? 'researchLine')
		get_research_line(element)
	end
end

def get_name(element, sub)
	name = element.content.strip
	if(sub)
		name.gsub!(/Mestre.*/, "")
		name.gsub!(/\s+/, " ")
		name.gsub!(/\(.*/, "")
		name.sub! "   ", ""
		name.sub! "   ", " "
		name.sub! "  ", " "
		name.gsub!(/ */, "") #FACCAMP 160.chr "\xA0"
		name.gsub! /\n.*/, ""
		# name.sub! /Dr /, ""
		# name.sub! /Dr\./, ""
		name.sub!(/,.*/, "")
		name.sub! /Doutor.*/, ""
		name.sub! /.*[D]r[aª]?\.? /, ""
		name.sub! /.*dr[a]?\. /, ""
		name.sub! /Durante.*/, ""
		name.sub! /.*Profa. Dra./,""
		name.sub! /\(Lattes\).*/, ""
		# name.sub! /Prof /, ""
		name.sub! /.*Prof[aª]?\.? ?/, ""
		name.sub! "• ", ""
		name.sub! /:.*/, ""
		name.sub! "d’", "d'"
		name.sub! "d´", "d'"
		name.sub!(/\w*@.*/, "") #ufmg
		name.sub!(/ -.*/, "")
		name.sub!(/ ?\(.*\)/, "")
		name.sub!(/ \[e-mail.*/, "") #ufpb
		name.gsub!(/^\s*/, "")
		name.gsub!(/\s?Área/, "")
		name.gsub!(/\s*$/, "")
		name.sub! "Durante os 3 anos seu PhD", ""
		name.sub! "Professor Departamento Ciencia Computacao Universidade Brasilia", ""
	end
	name
end

def get_lattes(element)
	unless element == 'undefined' || element[:href] == 'http://lattes.cnpq.br/'
		url = element[:href]
		format = "buscatextual.cnpq.br/buscatextual/visualizacv.jsp"
		if url.include? format
			url.sub! format, "buscatextual.cnpq.br/buscatextual/visualizacv.do"
		end
		url
	else
		'undefined'
	end
end

def get_image(element)
	element['src']
end

def get_email(element)
	element.content.strip
end

def get_research_line(element)
	element.children[2].content.strip #UFG
end

def get_url(url)
	uri = URI.parse(url)
	url = uri.scheme+'://'+uri.host
end

def process_sex()
	$researchersDump.each{|index, r|
		file = File.read('../data/namesMas.txt')
		names  = file.split("\n")
		if names.include? r['lattesName']
			$researchersDump[index]['gender'] = "M"
		else
			$researchersDump[index]['gender'] = "F"
		end
	}
	
end

def open_page(page, kind, idProgram)
	(0..10).each{|i|
		begin
			if (1..9).to_a.include? i
				sleep i*2
			end
			opened = ''
			if idProgram != nil
				if kind == '!'
					filename = "../data/pages/embedded/#{Digest::MD5.hexdigest(page)}.html"
				else
					filename = "../data/pages/#{idProgram}.html"
				end
				unless File.file?(filename)
					file = File.open(filename, "w")
				  open("#{page.strip}") do |uri|
				     file.write(uri.read)
				  end
				  print " [D] "
				end
				if [
					'28001010095P3', #UFBA
					'33002010176P0', #USP
					'33144010008P1', #UFABC ok
					'23002018002P4', #UERN ok 
					'28001010090P1', #UFBA ok [embedded]
					'28001010061P1', #UFBA ok [embedded]
					'22001018031P5', #UFC ok [embedded]
  				'25004018011P1', #FESP/UPE ok [nolattes]
  				'32008015011P7', #PUC/MG ok [embedded]
				].include? idProgram
					opened = File.read(filename, :encoding => 'iso-8859-1')	
				elsif [
					'32001010004P61','32001010004P62' #UFMG ok [nolattes]
				].include? idProgram
					open(filename, "r:ISO-8859-1:UTF-8") do |io|
					  opened = io.read
					end
				else
					opened = File.read(filename)	
				end
			else
				opened = open(page.strip)
			end
			return Nokogiri::HTML(opened)
		rescue
			if i == 10
				print " ##{i}#{kind} " 
				puts "\n"+page.inspect
				return nil
			else
				print " *#{i}#{kind} "
				#puts "\n#{page}" #if ["_", "!"].include? kind
			end
		end
	}
end


def open_page_rest(name)
	(0..10).each{|i|
		begin
			if (1..9).to_a.include? i
				sleep i*2
			end
			page = RestClient.post(
				'http://buscatextual.cnpq.br/buscatextual/busca.do', 
				'metodo=buscar&filtros.buscaNome=true&buscarDoutores=true&textoBusca='+name,
				:verify_ssl => false
			)

			return page
		rescue
			if i == 10
				print "##{i}R" 
				return nil
			else
				print "*#{i}R" 
			end
		end
	}
end

def extract_id_lattes(url)
	uri = URI.parse(url)
	if uri.host == nil
		rand(100)
	elsif uri.path[1..-1].length == 16
		uri.path[1..-1]
	elsif [10,7].include? CGI::parse(uri.query)['id'][0].length
		CGI::parse(uri.query)['id'][0]
	end
end

def extract_page(programsIds, researchers)
	threadsResearchPool = Thread.pool(73)
	programResearchersInfo = {}

	programsIds.each_with_index do |idProgram, index|
		threadsResearchPool.process do
			begin
				researchers[idProgram] = {}
				programInfo = $programsInfo[idProgram]

				# puts "\n"+(index+1).to_s+" - "+programInfo.values[0..2].join(' ')+"\n"
				# print " #{(index+1).to_s} "
				$mutex.synchronize do
					print " #{$countResearch} "
					$countResearch+=1
				end

				# genarating Researchers Info
				programResearchersInfo[idProgram] = []
				if ['31001017004P3', '32001010004P6'].include? idProgram #UFRJ, UFMG multiple pages
					count = 0
					programInfo['researchers'].each{ |page|
						count+=1
						doc = open_page(page, '_', idProgram+count.to_s)
						programResearchersInfo[idProgram].concat extract_researchers_info(idProgram, doc)
					}
				else
					page = programInfo['researchers']
					doc = open_page(page, '_', idProgram)
					programResearchersInfo[idProgram] = extract_researchers_info(idProgram, doc)
				end
				# puts "================="
				# puts programResearchersInfo[idProgram].inspect
			rescue
				puts $!, $@
			end
		end
	end

	threadsResearchPool.shutdown
	programResearchersInfo
end


def extract_researchers_info(idProgram, doc)

	programResearchersInfo = []
	programInfo = $programsInfo[idProgram]

	unless idProgram == "15001016047P9" # UFPA PDF
		fields = {}	

		if(['53001010098P3', 'fff'].include? idProgram) #unb, cesar
			temp = ''
			if(idProgram == '53001010098P3')
				temp = JSON.parse(File.read('../data/lattes-unb.json'))
			elsif(idProgram == 'fff')
				temp = JSON.parse(File.read('../data/lattes-pq.json'))
			end
			fields['names'] = []
			fields['lattes'] = []
			temp.each{|r|
				fields['names'] << r['names']
				fields['lattes'] << r['lattes']
			}
		else
			# extract infos form crawlerSchema
			programInfo['crawlerSchema'].each { |field|
				next if field[0] == 'embedded'
				
				# without lattes
				if field[0] == 'lattes' && field[1] == ""
					length = fields['names'].length
					fields['lattes'] = Array.new(length){|i| "undefined"}
					next 
				end
				fields[field[0]] = doc.css(field[1])
			}
		end

		# puts fields['names'].length
		# puts fields['lattes'].length
		# puts fields.inspect

		# infos form crawlerSchema and extract embedded
		threadsField = []
		
		$sizes[idProgram] = fields['names'].length
		fields['names'].each_with_index do |name, index|
			researcher = {}
			
			programInfo['crawlerSchema'].keys.each do |field|
				if(field != 'embedded')
					# puts field, fields[field][index].inspect
					if(field == 'lattes' && ([
						'Hannu Tapio Ahonen',
						'Edilson de Aguiar',
						'Joan Climent Vilaró',
						'Marina Groshaus',
						].include? researcher['names']))
						researcher['lattes'] = 'undefined'
					else
						if(['53001010098P3', 'fff'].include? idProgram)
							researcher[field] = fields[field][index]
						else
							researcher[field] = get_field(field, fields[field][index])
						end
					end
					# puts researcher[field]
				else
					# Open researcher homepage embedded
					threadsField << Thread.new do

						path = name[:href]
						path = "/"+path unless path[0] == "/"
						
						url = get_url(programInfo['homepage'])+path

						if(["22001018031P5", "33003017005P8", "27001016029P4", "42001013004P4", "42002010036P3", "33001014008P4", "40004015019P5",].include? idProgram)
							if idProgram == "22001018031P5" #ufc
								url = "http://mdcc.ufc.br/static"+path[2..-1] 
							elsif idProgram == "33003017005P8" #unicamp
								url = "http://www.ic.unicamp.br"+path 
							elsif idProgram == "27001016029P4" #ufs
								url = "https://www.sigaa.ufs.br"+path 
							elsif idProgram == "42001013004P4" #ufrgs
								url = path[1..-1] 
							elsif idProgram == "42002010036P3" #ufsm
								url = path[1..-1] 
							elsif idProgram == "33001014008P4" #ppgcc ufscar
								url = "http://ppgcc.dc.ufscar.br/pessoas/docentes-1"+path 
							elsif idProgram == "40004015019P5" #uem
								url = "http://www.din.uem.br"+path[6..-1]
							end 
						else
							url = name[:href] if(name[:href].include? "cnpq.br")
						end
						# puts url

						begin
							if (([
								"ttp://rocha.ucpel.tche.br/", #ufrgs
								"http://www.cos.ufrj.br/http://orion.lcg.ufrj.br/roma",
								"http://www.cos.ufrj.br/http://www.lcg.ufrj.br/Members/esperanc",
								"http://www.cos.ufrj.br/http://www.lcg.ufrj.br/Members/ricardo",
								"http://ppgcc.dc.ufscar.br/pessoas/docentes-1/joao-paulo-papa"
							].include? url) || (url.include? "mailto"))
								raise "Invalid URL" #TODO
							end
							# open(url)
							# get_url_embedded(name[:href])
							homepage = open_page(url, '!', idProgram)
							programInfo['crawlerSchema']['embedded'].each do |field|
								if([
									'Paul Denis Etienne Regnier',
								].include? researcher['names']) # Não possui lattes
									researcher['lattes'] = 'undefined'
								elsif(homepage.css(field[1]).size != 0)
									value = get_field(field[0], homepage.css(field[1])[0])
									if(field[0] == 'name')
										researcher['names'] = value
									else
										researcher[field[0]] = value
									end
								else
									researcher[field[0]] = 'undefined'
								end
								# puts researcher[field[0]]
							end	
						rescue #OpenURI::HTTPError
							print '?'
							# puts $!, $@
							# puts url.title
							researcher['lattes'] = 'undefined'
						end
					end
				end
			end
			programResearchersInfo << researcher
		end

		threadsField.each do |t|
			t.join
			print '!'
		end
	else # UFPA PDF
		programResearchersInfo = JSON.parse(File.read("../data/lattes-ufpa.json"))
	end

	programResearchersInfo
end

def get_info_from_lattes_page(name)
	info = {}
	unless $ids.keys.include? name
		name = name.tr(
			"ÀÁÂÃÄÅàáâãäåĀāĂăĄąÇçĆćĈĉĊċČčÐðĎďĐđÈÉÊËèéêëĒēĔĕĖėĘęĚěĜĝĞğĠġĢģĤĥĦħÌÍÎÏìíîïĨĩĪīĬĭĮįİıĴĵĶķĸĹĺĻļĽľĿŀŁłÑñŃńŅņŇňŉŊŋÒÓÔÕÖØòóôõöøŌōŎŏŐőŔŕŖŗŘřŚśŜŝŞşŠšſŢţŤťŦŧÙÚÛÜùúûüŨũŪūŬŭŮůŰűŲųŴŵÝýÿŶŷŸŹźŻżŽž",
			"AAAAAAaaaaaaAaAaAaCcCcCcCcCcDdDdDdEEEEeeeeEeEeEeEeEeGgGgGgGgHhHhIIIIiiiiIiIiIiIiIiJjKkkLlLlLlLlLlNnNnNnNnnNnOOOOOOooooooOoOoOoRrRrRrSsSsSsSssTtTtTtUUUUuuuuUuUuUuUuUuUuWwYyyYyYZzZzZz"
		)
		name.gsub!(/ d[ao]s/, "")
		name.gsub!(/ d[eao]/, "")
		name.gsub!(/ [A-W]\./, "")
		# name.gsub!(/'/, "'")
		name.sub! "Luis Marianol Val Cura", "Luis Mariano Del Val Cura"
		name.sub! "Aleardo Manacero Jr", "Aleardo Manacero Junior"
		name.sub! "Nelson Delfino d`Avila Mascarenhas", "Nelson Delfino Mascarenhas"
		name.sub! "Rosangela Aparecida Delloso Penteado", "Rosangela Aparecida Dellosso Penteado"
		name.sub! "Andrey Elision Monteiro Brito", "Andrey Elisio Monteiro Brito"
		name.sub! "Leslie Richard Foulds", "Les Foulds"
		name.sub! "Thelma Elita Colanzi Lopes", "Thelma Elita Colanzi" #uem
		name.sub! "Linnyer Beatrys Ruiz Aylon", "Linnyer Beatrys Ruiz"#uem
		name.sub! "Ronaldo Farias Ramos", "Ronaldo Fernandes Ramos" #uece
		name.sub! "Maria Giovanise Oliveira Pontes", "Maria Gilvanise Oliveira Pontes" #uece
		name.sub! "Givandenys Leite Sales", "Gilvandenys Leite Sales" #uece
		name.sub! "Antonio Wendel Oliveira Rodrigues", "Antonio Wendell Oliveira Rodrigues" #uece
		name.sub! "Joao Porto Albuquerque Pereira", "Joao Porto Albuquerque" #usp
		name.sub! "Marcio Costa Perreira Brandao", "Marcio Costa Pereira Brandao" #unb
		name.sub! "Ricardo Pezzoul Jacobi", "Ricardo Pezzuol Jacobi"#unb
		name.sub! "Dr. Joao Mello Silva", "Joao Mello Silva"#unb
		name.sub! "Jussara Marques Almeida Goncalves", "Jussara Marques Almeida"
		name.sub! "Roberto Souto Maior Barros Filho", "Roberto Souto Maior Barros" #ufpe
		# puts
		# puts name
		# puts

		page = Nokogiri(open_page_rest(name))

		if 'Judith Kelner' == name #ufpe
			info[:name] = name
			info[:id10] = 'K4787292T5'
			return info
		end

		if 'Josenildo Costa Silva' == name #uema
			info[:name] = name
			info[:id10] = 'K4761150H5'
			return info
		end

		if 'Cicero Costa Quarto' == name #uema
			info[:name] = name
			info[:id10] = 'K4131583U3'
			return info
		end

		if 'Reinaldo Jesus Silva' == name #uema
			info[:name] = name
			info[:id10] = 'K4717514U8'
			return info
		end

		if 'Sindo Vasquez Dias' == name #unicamp
			info[:name] = name
			info[:id10] = 'K4776798Y3'
			return info
		end

		if 'Thelma Cecilia Chiossi' == name #unicamp
			info[:name] = name
			info[:id10] = 'K4780712U9'
			return info
		end

		if 'Fernando Antonio Vanini' == name #unicamp
			info[:name] = name
			info[:id10] = 'K8150979U6'
			return info
		end

		if 'Hemerson Pistori' == name #unicamp
			info[:name] = name
			info[:id10] = 'K4765793Y9'
			return info
		end

		if 'Renata Araujo' == name #unirio
			info[:name] = name
			info[:id10] = 'K4723617A6'
			return info
		end

		if 'Alexandre Rodrigues Gomes' == name #unb
			info[:name] = name
			info[:id10] = 'K4750654Z1'
			return info
		end

		if 'Ulisses Barbosa' == name
			return nil
		end

		return nil if page == nil

		result = page.css('div.resultado li:has(b a)')
		if result.length == 1
			link = page.css('div.resultado li b a')[0]
			info[:name] = link.content.strip
			info[:id10] = link['href'].split('\'')[1]
		else
			result.each{|r|
				# puts r.css('b a')[0].content.strip
				# puts r.css('b a')[0]['href']
				# puts r.content.strip
				if [
						'Computação', 
						'Engenharia', 
						'Doutorado em Medicina (Clínica Médica) - Ribeirão Preto',
						'Doutorado em Engenharia Elétrica pela University of Southern California, Estados Unidos', #ufscar
						'Doutorado em Filosofia pela Universidade Estadual de Campinas, Brasil(2005)',
						'Doutorado em Matemática pelo Technische Universität Berlin, Alemanha(1994)', #http://buscatextual.cnpq.br/buscatextual/visualizacv.do?metodo=apresentar&id=K4787082A4
						'Doutorado em Administração pela Universidade Federal do Rio de Janeiro' #http://buscatextual.cnpq.br/buscatextual/visualizacv.do?id=K4796353Z8
						].any? { |word| r.content.strip.include?(word) } 
					link = r.css('b a')[0]
					info[:name] = link.content.strip 
					info[:id10] = link['href'].split('\'')[1]
				end
			}
		end
		print '+'
	else
		# puts $ids[name]
		# puts $researchersDump[$ids[name]].inspect
		info[:name] = $researchersDump[$ids[name]]['lattesName']
		info[:id10] = $researchersDump[$ids[name]]['lattesId10']
		return nil if info[:id10] == '-'
	end
	info
end

def extract_info_from_field_lattes(url, name, idProgram)
	if(url == 'undefined' || !url.include?("cnpq.br") || (url.include?("buscatextual") && !url.include?("id")))
		info = get_info_from_lattes_page(name)
		# puts info.inspect
		if info == {} || info == nil
			# puts "Não foi encotrado na base de Doutores do Lattes"
			# print "x"
			puts "\nx#{name}#{$programsInfo[idProgram]['IES']}"
			return nil 
		end
		url = 'http://buscatextual.cnpq.br/buscatextual/visualizacv.do?id='+info[:id10]
	end
	infos = {}
	# puts "\n\n#{idProgram} #{url} #{name}\n"
	id = ''
	if(url.include? "http://lattes.cnpq.br/")
		id = url.strip.sub("http://lattes.cnpq.br/", "")
	elsif(url.include? "http://buscatextual.cnpq.br/buscatextual/visualizacv.do?metodo=apresentar&id=")
		id = url.strip.sub("http://buscatextual.cnpq.br/buscatextual/visualizacv.do?metodo=apresentar&id=", "")
	else
		id = url.strip.sub("http://buscatextual.cnpq.br/buscatextual/visualizacv.do?id=", "")
	end
	lattes = open_page(url.strip, '.', id)
	content = lattes.css('li:has(span.icone-informacao-autor.img_link)')[0].content.strip
	infos[:id16] = content.split('http://lattes.cnpq.br/')[1]

	# TODO name local & name lattes
	name = lattes.css('h2.nome')[0].content.strip
	if name.include? 'Bolsista'
		name = name.split 'Bolsista'
		infos[:name] = name[0]
		infos[:scholarship] = 'Bolsista'+name[1]
	else
		infos[:name] = name
		infos[:scholarship] = '-'
	end

	# TODO images
	infos[:image] = lattes.css('img.foto')[0][:src]

	infos[:id10] = infos[:image].sub("http://servicosweb.cnpq.br/wspessoa/servletrecuperafoto?tipo=1&id=", "")

	print '.'
	infos
end

# extract Info from Lattes
def extract_lattes(programResearchersInfo, researchers)
	threadsLattesPool = Thread.pool(300)
	programResearchersInfo.each_key do |idProgram|
		programResearchersInfo[idProgram].each do|researcher|
			threadsLattesPool.process do
				begin
					# puts "\n===\nname - "+researcher['names']+"\nlattes - "+researcher['lattes']

					lattesInfo = extract_info_from_field_lattes(researcher['lattes'], researcher['names'], idProgram)

					next if lattesInfo == nil

					researcher['lattesId16'] = lattesInfo[:id16]
					researcher['lattesId10'] = lattesInfo[:id10]
					researcher['lattesName'] = lattesInfo[:name]
					researcher['scholarship'] = lattesInfo[:scholarship]
					researcher['lattesImage'] = lattesInfo[:image]
					
					
					researchers[idProgram][lattesInfo[:id16]] = researcher
					$mutex.synchronize do
						print " [#{$count}] "
						$count += 1
					end

					if $researchersDump[lattesInfo[:id16]] != nil
						unless $researchersDump[lattesInfo[:id16]]['idProgram'].include? idProgram
							$researchersDump[lattesInfo[:id16]]['idProgram'] << idProgram
						end
					else
						$researchersDump[lattesInfo[:id16]] = {}
						$researchersDump[lattesInfo[:id16]]['lattesId16'] = lattesInfo[:id16]
						$researchersDump[lattesInfo[:id16]]['lattesId10'] = lattesInfo[:id10]
						# $researchersDump[lattesInfo[:id16]]['siteName'] = researcher['names']
						$researchersDump[lattesInfo[:id16]]['scholarship'] = lattesInfo[:scholarship]
						$researchersDump[lattesInfo[:id16]]['lattesName'] = lattesInfo[:name]
						$researchersDump[lattesInfo[:id16]]['lattesImage'] = lattesInfo[:image]
						$researchersDump[lattesInfo[:id16]]['idProgram'] = []
						$researchersDump[lattesInfo[:id16]]['idProgram'] << idProgram
					end

					# puts researcher.inspect
				rescue
					puts $!, $@
				end
			end
		end
		# puts researchers[idProgram]
	end
	threadsLattesPool.shutdown

	researchers
end


# def generate_stat()
# 	file = File.read('../data/pos.json').sub('var pos = ', '')
# 	$programsInfo = JSON.parse(file)

# 	file = File.read('../data/lattes-temp.json')
# 	lattes = JSON.parse(file)
def generate_stat(lattes)
	researchers = []

	lattes.each{|key, program|
		puts $programsInfo[key].values[0..2].join(' ')
		if $sizes[key] == program.length
			puts "======="
			puts program.length
		else
			puts "<<<<<<<", 
			$sizes[key], 
			">>>>>>>", 
			program.length
		end
		program.each{|key, research|
			researchers << key
		}
	}

	ufCount = {}
	genderMale = 0
	$researchersDump.each{|k,r|
		genderMale += 1 if r['gender'] == 'M'
		r['idProgram'].each {|p|
			uf = $programsInfo[p]['UF']
			if uf != ""
				if ufCount[uf] == "nil"
					ufCount[uf] = 1
				else
					ufCount[uf] = ufCount[uf].to_i + 1
				end
			end
		}
	}
	
	total = $researchersDump.length
	genderMale = (genderMale / total.to_f)*100
	puts "\nMasculino #{genderMale.round(2)}%"
	puts "\nTotal de pesquisadores #{researchers.length} #{researchers.uniq.length}"
	p ufCount.inspect

end