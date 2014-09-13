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
		get_name(element)
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

def get_name(element)
	element.content.strip
end

def get_lattes(element)
	unless element == 'undefined' || element[:href] == 'http://lattes.cnpq.br/'
		element[:href]
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
	uri.scheme+'://'+uri.host
end

def extract_researchers_info(idProgram, doc, programInfo)

	programResearchersInfo = []

	unless idProgram == "15001016047P9" # UFPA PDF
		fields = {}

		programInfo['crawlerSchema'].each { |field|
			next if field[0] == 'embedded'
			
			if field[0] == 'lattes' && field[1] == ""
				length = fields['names'].length
				fields['lattes'] = Array.new(length){|i| "undefined"}
				next 
			end
			
			fields[field[0]] = doc.css(field[1])
			
			if field[0] == 'names'
				fields['names'] = drop_empty_names(fields['names'])
			end
		}	

		threadsField = []
		fields['names'].each_with_index do |name, index|
			researcher = {}
			
			programInfo['crawlerSchema'].keys.each do |field|
				if(field != 'embedded')
					# puts field, fields[field][index].inspect
					researcher[field] = get_field(field, fields[field][index])
					# puts researcher[field]
				else
					# Open researcher homepage
					threadsField << Thread.new do
						print '?'
						if name[:href] == "http://rocha.ucpel.tche.br/" #UFRGS
							name[:href] = "/https://www.google.com/" # não tem lattes
						end

						path = name[:href]
						path = "/"+path unless path[0] == "/"
						url = get_url(programInfo['homepage'])+path
						url = "http://mdcc.ufc.br/static"+path[2..-1] if programInfo['homepage'] == "http://mdcc.ufc.br/"
						url = path[1..-1] if programInfo['homepage'] == "http://ppgc.inf.ufrgs.br/"
						url = "http://www.ic.unicamp.br"+path if programInfo['homepage'] == "http://www.ic.unicamp.br/pos"
						url = path[1..-1] if programInfo['homepage'] == "http://w3.ufsm.br/ppgi/"
						url = "http://ppgcc.dc.ufscar.br/pessoas/docentes-1"+path if programInfo['homepage'] == "http://ppgcc.dc.ufscar.br/"
						url = "http://www.din.uem.br"+path[6..-1] if programInfo['homepage'] == "http://www.din.uem.br/pos-graduacao/mestrado-em-ciencia-da-computacao/"
						# puts url
						
						begin
							homepage = Nokogiri::HTML(open(url))
							programInfo['crawlerSchema']['embedded'].each do |field|
								if(homepage.css(field[1]).size != 0)
									value = get_field(field[0], homepage.css(field[1])[0])
									if(field[0] == 'name')
										researcher['names'] = value
									elsif(field[0] == 'lattes2')
										if(value != 'undefined')
											researcher['lattes'] = value
										end
									else
										researcher[field[0]] = value
									end
								else
									if(field[0] != 'lattes2')
										researcher[field[0]] = 'undefined'
									end
								end
								# puts researcher[field[0]]
							end	
						rescue
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
		programResearchersInfo = JSON.parse(File.read("lattes-ufpa.json"))
	end

	programResearchersInfo
end

def drop_empty_names(values)
	values.reject do |element|
		[
			" ",
			"PROFESSORES CO-ORIENTADORES",
			"Docente",
			"",
			"Sala:",
			"E-mail:",
			"Professor",
			"orientar D.Sc.?",
		 	"temporario01", #regex TODO
			"temporario02", #regex TODO
			"temporario03", #regex TODO
			"temporario04", #regex TODO
			"colaborador05", #regex TODO
			"Nelson Castro Machado",
			"http://www.meira.com",
			"www.engenhariadevendas.com.br",
			"http://aisapereira.blogspot.com",
			" O mestrado profissional é formado por:",
			"Vice Coordenadora - MPCOMP",#UECE
			"Coordenador Geral MPCOMP",
			"  -Coordenador de Área - REDES",
			"PROFESSORES COLABORADORESÂ ",
			"Nome",
			"Permanentes (Aprovados pela CAPES)", #UEMA
			"Colaboradores",
		].include? get_name(element)  
	end
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

def get_info_from_lattes_page(name)
	
	name.sub! " -Â ", "" #unifacs
	name.sub! "Â ", ""
	name.sub! "Ã©", "e"
	name.sub! "Ã¡", "a"
	name.sub! "Ã­", "i"
	name.sub! "Ã¨", "e"

	name = name.tr(
		"ÀÁÂÃÄÅàáâãäåĀāĂăĄąÇçĆćĈĉĊċČčÐðĎďĐđÈÉÊËèéêëĒēĔĕĖėĘęĚěĜĝĞğĠġĢģĤĥĦħÌÍÎÏìíîïĨĩĪīĬĭĮįİıĴĵĶķĸĹĺĻļĽľĿŀŁłÑñŃńŅņŇňŉŊŋÒÓÔÕÖØòóôõöøŌōŎŏŐőŔŕŖŗŘřŚśŜŝŞşŠšſŢţŤťŦŧÙÚÛÜùúûüŨũŪūŬŭŮůŰűŲųŴŵÝýÿŶŷŸŹźŻżŽž",
		"AAAAAAaaaaaaAaAaAaCcCcCcCcCcDdDdDdEEEEeeeeEeEeEeEeEeGgGgGgGgHhHhIIIIiiiiIiIiIiIiIiJjKkkLlLlLlLlLlNnNnNnNnnNnOOOOOOooooooOoOoOoRrRrRrSsSsSsSssTtTtTtUUUUuuuuUuUuUuUuUuUuWwYyyYyYZzZzZz"
	)
	name.sub! "   ", ""
	name.sub! "   ", " "
	name.sub! "  ", " "
	name.gsub! /\n.*/, ""
	name.sub! /Doutor.*/, ""
	name.sub! /Drª /, ""
	name.sub! /Dr./, ""
	name.sub! /Dra\. /, ""
	name.sub! /dr\. /, ""
	name.sub! /Profª /, ""
	name.sub! /.*Prof(a)?\. /, ""
	name.sub! "• ", ""
	name.sub! /:.*/, ""
	name.gsub!(/ d[ao]s/, "")
	name.gsub!(/ d[eao]/, "")
	name.gsub!(/ [A-W]\./, "")
	name.sub! "d´", "d'"
	name.sub!(/ -.*/, "")
	name.sub!(/,.*/, "")
	name.sub!(/ \(.*\)/, "")
	name.sub! /colaborador0\d/, ""
	name.sub! "Durante os 3 anos seu PhD", ""
	name.sub! "Leslie Richard Foulds", "Les Foulds"
	name.sub! "Professor Departamento Ciencia Computacao Universidade Brasilia", ""
	name.sub! "Ronaldo Farias Ramos", "Ronaldo Fernandes Ramos" #uece
	name.sub! "Maria Giovanise Oliveira Pontes", "Maria Gilvanise Oliveira Pontes" #uece
	name.sub! "Givandenys Leite Sales", "Gilvandenys Leite Sales" #uece
	name.sub! "Antonio Wendel Oliveira Rodrigues", "Antonio Wendell Oliveira Rodrigues" #uece
	name.sub! "Joao Porto Albuquerque Pereira", "Joao Porto Albuquerque" #usp
	name.sub! "Marcio Costa Perreira Brandao", "Marcio Costa Pereira Brandao" #unb
	name.sub! "Ricardo Pezzoul Jacobi", "Ricardo Pezzuol Jacobi"#unb
	name.sub! "Dr. Joao Mello Silva", "Joao Mello Silva"#unb
	name.sub! "Jussara Marques Almeida Goncalves", "Jussara Marques Almeida"
	name.sub! "Roberto Souto Maior de Barros Filho", "Roberto Souto Maior de Barros" #ufpe
	# puts
	# puts name
	# puts
	info = {}
	# t = Thread.new do
		page = RestClient.post(
			'http://buscatextual.cnpq.br/buscatextual/busca.do', 
			'metodo=buscar&filtros.buscaNome=true&buscarDoutores=true&textoBusca='+name,
			:verify_ssl => false
		)
		page = Nokogiri::HTML(page)
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
						'Doutorado em Matemática pelo Technische Universität Berlin, Alemanha(1994)', #http://buscatextual.cnpq.br/buscatextual/visualizacv.do?metodo=apresentar&id=K4787082A4
						'Doutorado em Administração pela Universidade Federal do Rio de Janeiro' #http://buscatextual.cnpq.br/buscatextual/visualizacv.do?id=K4796353Z8
						].any? { |word| r.content.strip.include?(word) } 
					link = r.css('b a')[0]
					info[:name] = link.content.strip 
					info[:id10] = link['href'].split('\'')[1]
				end
			}
		end
		print '.'
	# end
	# t.join
	info
end

def extract_info_from_field_lattes(url, name)
	if(url == 'undefined' || !url.include?("cnpq.br") || (url.include?("buscatextual") && !url.include?("id")))
		info = get_info_from_lattes_page(name)
		if info == {}
			# puts "Não foi encotrado na base de Doutores do Lattes"
			print "x"
			return nil 
		end
		url = 'http://buscatextual.cnpq.br/buscatextual/visualizacv.do?id='+info[:id10]
	end
	infos = {}
	format = "http://buscatextual.cnpq.br/buscatextual/visualizacv.jsp"
	if url.include? format
		url.sub! format, "http://buscatextual.cnpq.br/buscatextual/visualizacv.do"
	end
	# TODO corrigir thread
	# t = Thread.new do
		lattes = Nokogiri::HTML(open(url.strip))

		content = lattes.css('li:has(span.icone-informacao-autor.img_link)')[0].content.strip
		infos[:id16] = content.split('http://lattes.cnpq.br/')[1]

		# TODO name local & name lattes
		infos[:name] = lattes.css('h2.nome')[0].content.strip

		# TODO images
		infos[:image] = lattes.css('img.foto')[0][:src]

		print '.'
	# end
	# t.join
	infos
end