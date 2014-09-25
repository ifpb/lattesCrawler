require 'nokogiri'
require 'open-uri'
require 'net/https'
require 'json'
require 'openssl'
require 'thread/pool'
require 'digest'
require './util.rb'

# TODO 
# Dump pages (pos)
# (colaborador, permantente)
# Try SocketError [`initialize': getaddrinfo: nodename nor servname provided, or not known (SocketError)]
# try offline
# try delay open
# tuning pool
# check all Thread
# TODO no match
# comment puts
# thread output, rescue 
# warning: already initialized constant OpenSSL::SSL::VERIFY_PEER
# WARNING: OpenSSL::SSL::VERIFY_PEER == OpenSSL::SSL::VERIFY_NONE
# This dangerous monkey patch leaves you open to MITM attacks!
# Try passing :verify_ssl => false instead
# OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

#rescue all threads
#thread block access +=1

puts "\n\n\n===>Iniciando o crawler\n\n"
start_time = Time.now
$count = 1
$countResearch = 1
$mutex = Mutex.new
$sizes = {}
researchers = {}
file = File.read('../data/ids.json')
$researchersDump = JSON.parse(file)
file = File.read('../data/pos.json').sub('var pos = ', '')
$programsInfo = JSON.parse(file)
file = File.read('../data/pq2013-ciencias-da-computacao.json')
$pq = JSON.parse(file)

$ids = {}
# $researchersDump.map{|a, b| $ids[$researchersDump[a]['siteName']] = $researchersDump[a]['lattesId16']}
$researchersDump = {}
$researchers = {}

# puts $ids.inspect



begin
	threadsLattesPool = Thread.pool(300)
	$pq.each{|index, r|
		threadsLattesPool.process do
			begin
				# puts $pq[index]['curriculo_candidato_t'], $pq[index]['nome_candidato_t']

				url = $pq[index]['curriculo_candidato_t']

				id = url.strip.sub("http://lattes.cnpq.br/", "")
				# puts id

				lattes = open_page(url, '.', id)
				
				
				lattesInfo = {}

				content = lattes.css('li:has(span.icone-informacao-autor.img_link)')[0].content.strip
				lattesInfo[:id16] = content.split('http://lattes.cnpq.br/')[1]

				name = lattes.css('h2.nome')[0].content.strip
				
				if name.include? 'Bolsista'
					name = name.split 'Bolsista'
					lattesInfo[:name] = name[0]
					lattesInfo[:scholarship] = 'Bolsista'+name[1]
				else
					lattesInfo[:name] = name
					lattesInfo[:scholarship] = '-'
				end

				lattesInfo[:image] = lattes.css('img.foto')[0][:src]

				lattesInfo[:id10] = lattesInfo[:image].sub("http://servicosweb.cnpq.br/wspessoa/servletrecuperafoto?tipo=1&id=", "")

				print '.'
				researcher = {}
				researcher['lattesId16'] = lattesInfo[:id16]
				researcher['lattesId10'] = lattesInfo[:id10]
				researcher['lattesName'] = lattesInfo[:name]
				researcher['scholarship'] = lattesInfo[:scholarship]
				researcher['lattesImage'] = lattesInfo[:image]
				
				
				$researchers[lattesInfo[:id16]] = researcher

				$mutex.synchronize do
					print " [#{$count}] "
					$count += 1
				end

				$researchersDump[lattesInfo[:id16]] = {}
				$researchersDump[lattesInfo[:id16]]['lattesId16'] = lattesInfo[:id16]
				$researchersDump[lattesInfo[:id16]]['lattesId10'] = lattesInfo[:id10]
				$researchersDump[lattesInfo[:id16]]['siteName'] = researcher['names']
				$researchersDump[lattesInfo[:id16]]['scholarship'] = lattesInfo[:scholarship]
				$researchersDump[lattesInfo[:id16]]['lattesName'] = lattesInfo[:name]
				$researchersDump[lattesInfo[:id16]]['lattesImage'] = lattesInfo[:image]

				# puts researcher.inspect
			rescue
				puts $!, $@
			end
		end
	}
	threadsLattesPool.shutdown
rescue
	puts $!, $@
end

puts "\n\n===>Gerando o arquivo lattes-schemas.json"


puts "\n\n===>Gerando o arquivo lattesPQ2013.json"
file = File.open("../data/lattesPQ2013.json", "w")
file.write(JSON.pretty_generate($researchers))

# puts "\n\n===>Gerando o arquivo ids.json"
# file = File.open("../data/ids.json", "w")
# file.write(JSON.pretty_generate($researchersDump))

puts "\n#{(Time.now - start_time)/60} min"
puts "\n===>Finalizando o crawler"

