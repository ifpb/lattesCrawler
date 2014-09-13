require 'nokogiri'
require 'open-uri'
require 'net/https'
require 'json'
require 'openssl'
require 'thread/pool'
require './util.rb'

# TODO 
# (colaborador, permantente)
# Try SocketError [`initialize': getaddrinfo: nodename nor servname provided, or not known (SocketError)]
# offline
# tuning pool
# check all Thread
# comment puts
# warning: already initialized constant OpenSSL::SSL::VERIFY_PEER
# WARNING: OpenSSL::SSL::VERIFY_PEER == OpenSSL::SSL::VERIFY_NONE
# This dangerous monkey patch leaves you open to MITM attacks!
# Try passing :verify_ssl => false instead
# OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

puts "\n\n\n===>Iniciando o crawler\n\n"
start_time = Time.now

threadsResearchPool = Thread.pool(10)

file = File.read('../data/pos.json').sub('var pos = ', '')
pograms = JSON.parse(file)

researchers = {}
[
	'28001010095P3', #UFBA ok [embedded] 6 undefined lattes 
	'22003010018P1', #UECE ok
	'22008012004P2', #IFCE ok
	'52001016027P2', #UFG ok [embedded] colaboradores 
	'20001010022P0', #UFMA ok 4 nomes errados
	'32002017027P2', #UFV ok    
	'32004010027P9', #UFLA ok
	'32005016034P8', #UFJF ok
	'32006012017P2', #UFU ok
	'32007019023P9', #UFOP ok
	'51001012012P2', #UFMS ok [embedded] temporario0\d e mestres
	'15001016047P9', #UFPA ok [pdf]
	'24009016005P0', #UFCG ok
	'21001014031P2', #FUFPI ok [embedded+/-]
	'40002012033P5', #UEL ok
	'40004015019P5', #UEM ok [embedded]
	'42005019016P8', #PUCRS ok http://buscatextual.cnpq.br/buscatextual/busca.do?metodo=apresentar
	'27001016029P4', #FUFSE ok [nolattes]
	'33001014008P4', #UFSCAR ok [embedded]
	'33001014044P0', #UFSCAR ok
	'33002010176P0', #USP ok [nolattes]
	'33003017005P8', #UNICAMP ok+/- [embedded] Nelson Castro Machado (Aposentado)
	'33004153073P2', #UNESP/SJRP ok ajax dynamic http://www.ibilce.unesp.br/?xajax=exibeCorpo&xajaxr=1410450693490&xajaxargs[]=2188&xajaxargs[]=&xajaxargs[]=
	'33009015079P0', #UNIFESP ok
	'33144010008P1', #UFABC ok
	'33149011002P1', #FACCAMP ok [embedded]
	'23002018002P4', #UERN ok
	'28001010090P1', #UFBA ok [embedded]
	'28001010061P1', #UFBA ok [embedded]
	'32003013008P4', #UNIFEI ok [embedded] #####
  '22001018031P5', #UFC ok [embedded]
  '32001010004P6', #UFMG ok [nolattes] colaboradores
  '25001019004P6', #UFPE ok [nolattes]
  '25001019062P6', #UFPE ok [nolattes, profissional]
  '41001010025P2', #UFSC ok +/-
  '33002045004P1', #USP/SC ok [nolattes] Colaboradores Externos
  '31003010046P4', #UFF ok
  '42001013004P4', #UFRGS ok [embedded]
  '42003016038P9', #UFPEL ok [embedded]
  '42004012022P1', #FURG ok
  '41005015010P7', #UNIVALI ok
  '22003010016P9', #UECE ok [nolattes, profissinal]
  '53001010098P3', #UNB ok [nolattes, profissional]
  '40006018011P7', #UTFPR ok [profissional]
  '42007011006P5', #UNISINOS ok
  '42009014011P1', #FUPF ok [profissional]
  '41002016023P2', #UDESC ok
  '25004018011P1', #FESP/UPE ok [nolattes]
  '20002017004P9', #UEMA ok [nolattes, profissional] (5M) Reinaldo Jesus Silva, Mauro Sergio Silva Pinto, Josenildo Costa Silva, Henrique Mariano Costa Amaral, Cicero Costa Quarto
  '31001017004P3', #UFRJ ok [embedded^2]
  '25019015001P0', #CESAR ok [profissional]
  '23001011071P0', #UFRN ok [embedded+/-, profissional]
  '26001012035P1', #UFAL ok
  '12001015012P2', #UFAM ok [embedded]
  '53001010054P6', #UNB ok 
  '30001013007P0', #UFES ok
  '32008015011P7', #PUC/MG ok [embedded]
  '24001015047P4', #UFPB ok
  '40001016034P5', #UFPR ok +/- Joan Climent Vilaró (Visitante)
  '40003019004P1', #PUC/PR ok 
  '40006018025P8', #UTFPR ok [profissional]
  '31001017110P8', #UFRJ ok [nolattes] +/- Pedro Salenbauch
  '31005012004P9', #PUC-RIO ok +/- horistas
  '31021018009P9', #UNIRIO ok [nolattes]
  '42002010036P3', #UFSM ok [embedded]
  '22002014002P1', #UNIFOR ok [nolattes]
  '25003011032P2', #UFRPE ok
  '33002010214P0', #USP ok [good]
  '28013018005P5', #UNIFACS ok [nolattes]
  '31007015009P3', #IME ok
  '23001011022P9', #UFRN ok [embedded]	
  '51001012028P6', #UFMS ok [ssl]
  '51001012038P1', #UFMS ok [profissional, ssl]
].each_with_index do |idProgram, index|
	threadsResearchPool.process do
		researchers[idProgram] = {}
		programInfo = pograms[idProgram]

		# puts "\n"+(index+1).to_s+" - "+programInfo.values[0..2].join(' ')+"\n"
		print " #{(index+1).to_s} "

		# genarating Researchers Info
		programResearchersInfo = []
		if idProgram == '31001017004P3' #UFRJ multiple pages
			programInfo['researchers'].each{ |page|
				doc = Nokogiri::HTML(open(page))
				programResearchersInfo.concat extract_researchers_info(idProgram, doc, programInfo)
			}
		else
			page = programInfo['researchers']
			if(['51001012028P6', '51001012038P1'].include? idProgram) #UFMS SSL
				print '#'
				sleep 15 
				OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE 
			end
			doc = Nokogiri::HTML(open(page))
			programResearchersInfo = extract_researchers_info(idProgram, doc, programInfo)
		end
		# puts "================="
		# puts programResearchersInfo.inspect
		
		# extract Info from Lattes
		threadsLattesPool = Thread.pool(30)
		programResearchersInfo.each do |researcher|
			threadsLattesPool.process do
				# puts "\n===\nname - "+researcher['names']+"\nlattes - "+researcher['lattes']
				# puts researcher.inspect

				lattesInfo = extract_info_from_field_lattes(researcher['lattes'], researcher['names'])

				next if lattesInfo == nil

				researcher['lattesId16'] = 'http://lattes.cnpq.br/'+lattesInfo[:id16]
				researcher['lattesName'] = lattesInfo[:name]
				researcher['lattesImage'] = lattesInfo[:image]
				
				researchers[idProgram][lattesInfo[:id16]] = researcher
				# puts researchers[idProgram]
			end
		end
		threadsLattesPool.shutdown
	end
end
threadsResearchPool.shutdown

puts "\n\n===>Gerando o arquivo lattes.json"

file = File.open("lattes.json", "w")
# puts researchers.to_json
file.write(JSON.pretty_generate(researchers))

puts "\n#{(Time.now - start_time)/60} min"
puts "\n===>Finalizando o crawler"








