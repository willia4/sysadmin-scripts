require 'net/http'
require 'rexml/document'

BASE_URL = 'http://www.goodreads.com/'

class GoodreadsImporter
	def initialize(api_key)
		@api_key = api_key
	end

	def listBooks(user_id, number)
		url = BASE_URL + "review/list.xml?key=#{@api_key}&id=#{user_id}&sort=date_read&order=d&per_page=#{number}&shelf=read"
		xml_data = Net::HTTP.get_response(URI.parse(url)).body

		books = []
		doc = REXML::Document.new(xml_data)

		doc.elements.each('GoodreadsResponse/books/book') do |ele|
			#print 
			book = 	{
						:id => ele.elements["id"].text, 
						:title => ele.elements["title"].text
					}
			books << book
		end

		return books
	end
end