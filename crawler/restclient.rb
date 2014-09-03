require 'rest_client'
require 'nokogiri'
require 'cgi'

# name = CGI.escape('Marcos Barreto') #Marcos+Barreto
# name = CGI.escape('Lais Salvador')
# name = CGI.escape('Gustavo Bittencourt')
name = CGI.escape('Steffen Lewitzka')
# name = CGI.escape('Adolfo Duran')
page = RestClient.post(
	'http://buscatextual.cnpq.br/buscatextual/busca.do', 
	'metodo=buscar&filtros.buscaNome=true&textoBusca='+name
)
file = File.open("temp.html", "w")
file.write(page)
page = Nokogiri::HTML(page)
result = page.css('div.resultado li:has(b a)')
# puts result.inspect
if result.length == 1
	link = page.css('div.resultado li b a')[0]
	puts link.content.strip
	id = link['href'].split('\'')[1]
	puts id
else
	result.each{|r|
		if r.content.strip.include? 'Computação'
			link = r.css('b a')[0]
			puts link.content.strip 
			id = link['href'].split('\'')[1]
			puts id
		end
	}
end