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

$ids = {}
$researchersDump.map{|a, b| $ids[$researchersDump[a]['siteName']] = $researchersDump[a]['lattesId16']}
# puts $ids.inspect

programsIds1 = [
  'fff',
	'28001010095P3', #UFBA ok [embedded] 6 undefined lattes 
	'22003010018P1', #UECE ok 
	'22008012004P2', #IFCE ok
	'52001016027P2', #UFG ok [embedded]
	'20001010022P0', #UFMA ok empty names
	'32002017027P2', #UFV ok    
	'32004010027P9', #UFLA ok
	'32005016034P8', #UFJF ok
	'32006012017P2', #UFU ok
	'32007019023P9', #UFOP ok
	'51001012012P2', #UFMS ok
	'15001016047P9', #UFPA ok [pdf]  xmltopdf
	'24009016005P0', #UFCG ok [nolattes+/-]
	'21001014031P2', #FUFPI ok [embedded+/-]
	'40002012033P5', #UEL ok
	'40004015019P5', #UEM ok [embedded] coordenadores duplicados
	'42005019016P8', #PUCRS ok http://buscatextual.cnpq.br/buscatextual/busca.do?metodo=apresentar
	'27001016029P4', #FUFSE ok [nolattes]
	'33001014008P4', #UFSCAR ok [embedded]
	'33001014044P0', #UFSCAR ok
	'33002010176P0', #USP ok [nolattes]
	'33003017005P8', #UNICAMP ok PÁG TODOS DOC (2M)Fernando Antônio Vanini, Thelma Cecilia dos Santos Chiossi (1E)Sindo Vasquez Dias (Aposentado)Nelson Castro Machado 
	'33004153073P2', #UNESP/SJRP ok ajax dynamic http://www.ibilce.unesp.br/?xajax=exibeCorpo&xajaxr=1410450693490&xajaxargs[]=2188&xajaxargs[]=&xajaxargs[]=
	'33009015079P0', #UNIFESP ok
	'33144010008P1', #UFABC ok [nomatch]
	'33149011002P1', #FACCAMP ok [embedded]
	'23002018002P4', #UERN ok 
	'28001010090P1', #UFBA ok [embedded]
	'28001010061P1', #UFBA ok [embedded]
	'32003013008P4', #UNIFEI ok [embedded] 
  '22001018031P5', #UFC ok [embedded] 
  '32001010004P6', #UFMG ok [nolattes] 
  '25001019004P6', #UFPE ok [nolattes] 
  '25001019062P6', #UFPE ok [nolattes, profissional] 
  '41001010025P2', #UFSC ok +/- [nomatch]
  '33002045004P1', #USP/SC ok [nolattes]
  '31003010046P4', #UFF ok
  '42001013004P4', #UFRGS ok [embedded]
  '42003016038P9', #UFPEL ok [embedded]
  '42004012022P1', #FURG ok
  '41005015010P7', #UNIVALI ok
  '22003010016P9', #UECE ok [nolattes, profissinal]
  '53001010098P3', #UNB ok [nolasttes, profissional] (2M)
  '40006018011P7', #UTFPR ok [profissional]
  '42007011006P5', #UNISINOS ok
  '42009014011P1', #FUPF ok [profissional] (2M) como colaborador
  '41002016023P2', #UDESC ok [nomatch]
  '25004018011P1', #FESP/UPE ok [nolattes]
  '20002017004P9', #UEMA ok [nolattes, profissional] (5M) Reinaldo Jesus Silva, Mauro Sergio Silva Pinto, Josenildo Costa Silva, Henrique Mariano Costa Amaral, Cicero Costa Quarto 
  '31001017004P3', #UFRJ ok [embedded^2]
  '25019015001P0', #CESAR ok [profissional] (6M)
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
  '31005012004P9', #PUC-RIO ok +/- horistas [charset]
  '31021018009P9', #UNIRIO ok [nolattes]
  '42002010036P3', #UFSM ok [nolattes]
  '22002014002P1', #UNIFOR ok [nolattes]
  '25003011032P2', #UFRPE ok 
  '33002010214P0', #USP ok [good]
  '28013018005P5', #UNIFACS ok [nolattes]
  '31007015009P3', #IME ok
  '23001011022P9', #UFRN ok [embedded]	
]

programsIds2 =[
  '51001012028P6', #UFMS ok [ssl]
  '51001012038P1', #UFMS ok [profissional, ssl]
]

begin
	programResearchersInfo1 = extract_page(programsIds1, researchers)
	puts
	extract_lattes(programResearchersInfo1, researchers)
	puts
	#UFMS
	OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
	programResearchersInfo2 = extract_page(programsIds2, researchers)
	puts
	extract_lattes(programResearchersInfo2, researchers)
rescue
	puts $!, $@
end

puts "\n\n===>Gerando o arquivo lattes-schemas.json"

file = File.open("../data/lattes-schemas.json", "w")
file.write(JSON.pretty_generate(programResearchersInfo1.merge(programResearchersInfo2)))

puts "\n\n===>Gerando o arquivo lattes.json"
file = File.open("../data/lattes.json", "w")
file.write(JSON.pretty_generate(researchers))

puts "\n\n===>Gerando o arquivo ids.json"
file = File.open("../data/ids.json", "w")
process_sex()
temp = $researchersDump.sort_by {|k, v| v['lattesName']}
$researchersDump = {}
temp.each{|k, v| $researchersDump[k] = v}
file.write(JSON.pretty_generate($researchersDump))

generate_stat(researchers)

puts "\n#{(Time.now - start_time)/60} min"
puts "\n===>Finalizando o crawler"

