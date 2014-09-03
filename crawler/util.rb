require 'uri/http'
require 'cgi'
require 'rest_client'
require 'nokogiri'

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
	unless element[:href] == 'http://lattes.cnpq.br/'
		element[:href]
	else
		'undefined'
		# 'http://lattes.cnpq.br/'+get_info_from_lattes_page(name)[:id10]
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

# TODO gets...

def get_url(url)
	uri = URI.parse(url)
	uri.scheme+'://'+uri.host
end

def drop_empty_names(values)
	values.reject do |element|
		[" ", "PROFESSORES CO-ORIENTADORES", "Docente", ""].include? get_name(element)  #UECE
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
	info = {}
	t = Thread.new do
		page = RestClient.post(
			'http://buscatextual.cnpq.br/buscatextual/busca.do', 
			'metodo=buscar&filtros.buscaNome=true&textoBusca='+name
		)
		page = Nokogiri::HTML(page)
		result = page.css('div.resultado li:has(b a)')
		if result.length == 1
			link = page.css('div.resultado li b a')[0]
			info[:name] = link.content.strip
			info[:id10] = link['href'].split('\'')[1]
		else
			result.each{|r|
				if r.content.strip.include? 'Computação'
					link = r.css('b a')[0]
					info[:name] = link.content.strip 
					info[:id10] = link['href'].split('\'')[1]
				end
			}
		end
		print '.'
	end
	t.join
	info
end

def extract_info_from_field_lattes(url, name)
	# puts url, info, name
	if(url == 'undefined')
		# return rand(1..1000)
		# return get_info_from_lattes_page(name)[:id10]
		url = 'http://buscatextual.cnpq.br/buscatextual/visualizacv.do?id='+get_info_from_lattes_page(name)[:id10]
	end
	infos = {}
	uri = URI.parse(url)
	# TODO corrigir thread
	t = Thread.new do
		lattes = Nokogiri::HTML(open(url))

		content = lattes.css('li:has(span.icone-informacao-autor.img_link)')[0].content.strip
		infos[:id16] = content.split('http://lattes.cnpq.br/')[1]
# 	infos[:id16] = uri.path[1..-1] if(uri.path.length == 17)

		# TODO lattes local & name lattes
		# TODO name local & name lattes
		infos[:name] = lattes.css('h2.nome')[0].content.strip

		# TODO images
		infos[:image] = lattes.css('img.foto')[0][:src]

		puts '.'
	end
	t.join
	infos
end