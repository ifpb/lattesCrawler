require 'nokogiri'
require 'open-uri'
require 'json'
require 'openssl'
require './util.rb'

OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
file = File.read('../data/pos.json').sub('var pos = ', '')
pos = JSON.parse(file)

puts "\n\n\n######\nIniciando o crawler\n\n"

researchers = {}
threadsResearch = []

# TODO (colaborador, permantente)
[
	# '28001010095P3', #UFBA ok 6 lattes undefined [embedded]
	# '22003010018P1', #UECE ok
	# '22008012004P2', #IFCE ok
	# '52001016027P2', #UFG ok lattes undefined Leslie Richard Foulds, colaboradores [embedded]
	# '20001010022P0', #UFMA ok 4 nomes errados
	# '32002017027P2', #UFV ok    
	# '32004010027P9', #UFLA ok
	# '32005016034P8', #UFJF ok
	# '32006012017P2', #UFU ok
	# '32007019023P9', #UFOP ok
	# '51001012012P2', #UFMS ok [embedded] temporario0x e mestres
	# '15001016047P9', #UFPA ok [PDF]
	# '24009016005P0', #UFCG ok
	# '21001014031P2', #FUFPI Falta lattes
	# '40002012033P5', #UEL ok
	# '40004015019P5', #UEM ok [embedded]
	# '42005019016P8', #PUCRS ok http://buscatextual.cnpq.br/buscatextual/busca.do?metodo=apresentar
	# '27001016029P4', #FUFSE Falta Lattes
	# '33001014008P4', #UFSCAR ok [embedded]
	# '33001014044P0', #UFSCAR ok
	# '33002010176P0', #USP Falta todos os lattes
	# '33003017005P8', #UNICAMP ok+/- [embedded] Nelson Castro Machado (Aposentado)
	# '33004153073P2', #UNESP/SJRP ok ajax dynamic http://www.ibilce.unesp.br/?xajax=exibeCorpo&xajaxr=1410450693490&xajaxargs[]=2188&xajaxargs[]=&xajaxargs[]=
	# '33009015079P0', #UNIFESP ok
	# '33144010008P1', #UFABC ok
	# '33149011002P1', #FACCAMP ok [embedded]
	# '23002018002P4', #UERN ok
	# '28001010090P1', #UFBA ok [embedded]
	# '28001010061P1', #UFBA ok [embedded]
	# '51001012028P6', #UFMS ok
	# '32003013008P4', #UNIFEI ok [embedded] 
  # '22001018031P5', #UFC ok [embedded]
  # '32001010004P6', #UFMG Falha Nenhum Lattes
  # '25001019004P6', #UFPE ok [embedded] Falta Mestrado
  # '25001019062P6', #UFPE ok [embedded+/-]
  # '41001010025P2', #UFSC ok +/-
  # '33002045004P1', #USP/SC Falta Lattes
  # '31003010046P4', #UFF ok
  # '42001013004P4', #UFRGS ok [embedded]
  # '42003016038P9', #UFPEL Falha offline
  # '42004012022P1', #FURG ok
  # '41005015010P7', #UNIVALI ok
  # '22003010016P9', #UECE falta lattes
  '53001010098P3', #UNB Falta [embedded]
  # '51001012038P1', #UFMS ok
  # '40006018011P7', #UTFPR ok
  # '42007011006P5', #UNISINOS ok
  # '42009014011P1', #FUPF ok
  # '41002016023P2', #UDESC ok
  # '25004018011P1', #UPE Falta Lattes
  # '20002017004P9', #UEMA Falta Lattes
  # '31001017004P3', #UFRJ [embedded^2]
  # '25019015001P0', #CESAR ok Profissional
  # '23001011071P0', #UFRN Profissional [embedded+/-]
  # '26001012035P1', #UFAL ok
  # '12001015012P2', #UFAM ok [embedded]
  # '53001010054P6', #UNB Falta [embedded] delay
  # '30001013007P0', #UFES ok
  # '32008015011P7', #PUC/MG ok [embedded]
  # '24001015047P4', #UFPB ok
  # '40001016034P5', #UFPR ok +/- Joan Climent Vilaró (Visitante)
  # '40003019004P1', #PUC/PR ok 
  # '40006018025P8', #UTFPR ok
  # '31001017110P8', #UFRJ Falta Lattes
  # '31005012004P9', #PUC-RIO ok +/- horistas
  # '31021018009P9', #UNIRIO falta todos os lattes
  # '42002010036P3', #UFSM ok [embedded]
  # '22002014002P1', #UNIFOR Falta Lattes
  # '25003011032P2', #UFRPE ok
  # '33002010214P0', #USP ok [bom]
  # '28013018005P5', #UNIFACS Falta lattes
  # '31007015009P3', #IME ok
  # '23001011022P9', #UFRN Falta lattes[embedded]	
].each do |idProgram|
	# TODO Try SocketError
	threadsResearch << Thread.new do
		researchers[idProgram] = {}
		researchersInfo = []
		info = pos[idProgram]
		puts "\n######\n"+info.values[0..2].join(' ')+"\n"

		doc = Nokogiri::HTML(open(info['researchers']))
		
		unless idProgram == "15001016047P9" # UFPA PDF
		fields = {}
		info['crawlerSchema'].each do |field|
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
		end	

		threadsField = []
		fields['names'].each_with_index do |name, index|
			researcher = {}
			
			# TODO id research form lattes
			info['crawlerSchema'].keys.each do |field|
				if(field != 'embedded')
					puts field, fields[field][index].inspect
					researcher[field] = get_field(field, fields[field][index])
					puts researcher[field]
				else
					# Open researcher homepage
					# TODO check all Thread
					threadsField << Thread.new do
						if name[:href] == "http://rocha.ucpel.tche.br/" #UFRGS
							name[:href] = "/https://www.google.com/" # não tem lattes
						end
						path = name[:href]
						path = "/"+path unless path[0] == "/"
						url = get_url(info['homepage'])+path
						url = "http://mdcc.ufc.br/static"+path[2..-1] if info['homepage'] == "http://mdcc.ufc.br/"
						url = path[1..-1] if info['homepage'] == "http://ppgc.inf.ufrgs.br/"
						url = "http://www.ic.unicamp.br"+path if info['homepage'] == "http://www.ic.unicamp.br/pos"
						url = path[1..-1] if info['homepage'] == "http://w3.ufsm.br/ppgi/"
						url = "http://ppgcc.dc.ufscar.br/pessoas/docentes-1"+path if info['homepage'] == "http://ppgcc.dc.ufscar.br/"
						url = "http://www.din.uem.br"+path[6..-1] if info['homepage'] == "http://www.din.uem.br/pos-graduacao/mestrado-em-ciencia-da-computacao/"
						puts url
						begin
							homepage = Nokogiri::HTML(open(url))
							info['crawlerSchema']['embedded'].each do |field|
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
			researchersInfo << researcher
		end

		threadsField.each do |t|
			t.join
			print '.'
		end

		end

		# UFPA PDF
		researchersInfo = JSON.parse(File.read("lattes-ufpa.json")) if idProgram == "15001016047P9"

		puts "================="
		puts researchersInfo.inspect
		
		researchersInfo.each do |researcher|
			puts "\n==="
			puts 'name - '+researcher['names']
			puts 'lattes - '+researcher['lattes']
			# puts researcher.inspect
			# idResearch = extract_id_lattes(researcher['lattes'])
			if(researcher['names'] == 'Leslie Richard Foulds')
				# TODO procurar por sobrenome
				researcher['lattes'] = 'http://buscatextual.cnpq.br/buscatextual/visualizacv.do?id=K4202000Z8'
			end
			lattesInfos = extract_info_from_field_lattes(researcher['lattes'], researcher['names'])
			next if lattesInfos == nil
			researcher['id16Lattes'] = 'http://lattes.cnpq.br/'+lattesInfos[:id16]
			researcher['lattesName'] = lattesInfos[:name]
			researcher['lattesImage'] = lattesInfos[:image]
			researchers[idProgram][lattesInfos[:id16]] = researcher
		end

	end
	# puts researchers[idProgram]
end

threadsResearch.each do |t|
	t.join
end

# puts researchers.to_json
puts "\n\n######\nGerando o arquivo lattes.json"
file = File.open("lattes.json", "w")
file.write(JSON.pretty_generate(researchers))
