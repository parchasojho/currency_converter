require "soap/wsdlDriver"
require 'rexml/document'
include REXML

$-w = nil
$check_if_valid = false
class Currency_converter
	def initialize(argument)
		@input = argument
		@xml_flag = true
		begin
			xmlfile = File.new("countries.xml")
			xmldoc = Document.new(xmlfile)
		rescue Errno::ENOENT => e
			puts "Can't find countries.xml!"
			@xml_flag = false
		end
		
		if @xml_flag
			#create a hash from countries.xml
			@country_hash = Hash.new
			xmldoc.elements.each("countries/country") do |country|
				country_name = country.attributes["countryName"]
				country_name.downcase!
				@country_hash[country_name] = country.attributes["currencyCode"]
			end

			#check if argument is a valid country or code. 
			if @country_hash.has_key?(@input)
				@to_currency = @country_hash[@input]
				$check_if_valid = true
			elsif @country_hash.has_value?(@input.upcase)
				@to_currency = @input.upcase!
				$check_if_valid = true
			else
				#can't find provided country or currency code
				puts "ERROR! Invalid input!"
			end
		end
	end

	def conversion
		begin
			#create the driver from the wsdl
			wsdl = "http://www.webservicex.net/CurrencyConvertor.asmx?WSDL"
			driver = SOAP::WSDLDriverFactory.new(wsdl).create_rpc_driver
			#create a hash that will be passed as parameters
			parameters = {"FromCurrency" => "PHP",
					"ToCurrency" => @to_currency
					}
			#call the operation and get the result
			result = driver.conversionRate(parameters).conversionRateResult
			puts "The equivalent of 1 PHP to #{@to_currency} is #{result}."
		rescue Errno::ETIMEDOUT => e
			#if connection attempt failed
			puts "Oops! Connection failed(Errno::ETIMEDOUT). Please try again."
		end
	end
end

#program needs an argument
if ARGV.length == 0
	puts "USAGE: ruby currency_converter.rb [country]"
	puts "For example: ruby currency_converter.rb Japan"
	puts "if program can't find [country], try to input the currency code."
	exit 1
end

#get argument. if it's more than one word, it will be combined into one string
argument = ""
ARGV.each do |argv|
	argument << "#{argv} "
end

#remove extra blank space at the end of the string argument
argument.downcase!
argument.slice!(argument.length-1)
convert = Currency_converter.new(argument)

#check_if_valid is false if the argument is not a valid country or currency, otherwise it is true
if $check_if_valid
	convert.conversion
end

