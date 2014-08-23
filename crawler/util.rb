require 'uri/http'
require 'cgi'

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
		get_name(element) == " " #UECE
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