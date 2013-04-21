require 'rubygems'
require 'html2md'
require 'hpricot'
require 'net/http'
require 'rexml/document'
require 'cgi'
require 'date'

BASE_URL = 'http://www.goodreads.com/'

class GoodreadsBook
	attr_accessor :id
	attr_accessor :title
	attr_accessor :author
	attr_accessor :author_url
	attr_accessor :goodreads_url
	attr_accessor :review_url
	attr_accessor :user_id

	def initialize(user_id, bookElement)
		self.id = bookElement.elements["id"].text
		self.title = bookElement.elements["title"].text
		self.author = "unknown"
		self.author_url = "http://goodreads.com"
		self.goodreads_url = bookElement.elements["link"].text
		self.user_id = user_id

		@api_image = bookElement.elements["image_url"].text
		@cached_cover_image = nil

		authors = REXML::XPath.match(bookElement, "authors/author")
		if authors.count > 0 then 
			self.author = authors[0].elements["name"].text
			self.author_url = authors[0].elements["link"].cdatas[0].to_s
		end
	end

	def coverImage
		if @cached_cover_image then
			print "cached"
			return @cached_cover_image
		end if 

		html_data = Net::HTTP.get_response(URI.parse(self.goodreads_url)).body

		img = Hpricot(html_data).at("//img[@id='coverImage']")
		if !img then
			return @api_image
		end

		img = (img['src']).to_s

		m = img.match /(.*)\/books\/([0-9]+).\/([0-9]+)\.jpg/

		if(!m) then
			return img
		end

		@cached_cover_image = m.captures[0] + '/books/' + m.captures[1] + 'm/' + m.captures[2] + '.jpg'
		return @cached_cover_image
	end
end

class GoodreadsReview
	attr_accessor :review_html
	attr_accessor :review_markdown
	attr_accessor :review_url
	attr_accessor :rating
	attr_accessor :user_id
	attr_accessor :date
	attr_accessor :book

	def initialize(book, reviewElement)
		self.book = book
		self.user_id = book.user_id

		self.review_html = reviewElement.elements["body"].cdatas[0].to_s
		self.review_url = reviewElement.elements["url"].cdatas[0].to_s

		self.rating = reviewElement.elements["rating"].text

		self.date = reviewElement.elements["read_at"].text
		
		#I'm not sure how to make strptime deal with the UTC offset. But we only care about the date, so match it. 
		m = date.match /^(.*) \d\d:\d\d:\d\d.*/
		self.date = Date.strptime(m.captures[0].to_s, "%a %b %d")
		
		self.review_markdown = Html2Md.new(self.review_html).parse
	end

	def review_flavoredmarkdown 
		return 	"Title: Review: #{self.book.title}  \n" + 
				"Date: #{self.date.strftime('%Y-%m-%d')}  \n" +
				"\n\n" +
				"[![#{self.book.title}][cover_image]][book_link]  \n" + 
				"*[#{self.book.title}][book_link]* by [#{self.book.author}][author_link]  \n\n" + 
			 	"My rating: [#{self.rating} of 5 stars][review_link]  \n\n" + 
			 	self.review_markdown + 
			 	"\n\n" + 
			 	"[cover_image]: #{self.book.coverImage} \n" + 
			 	"[book_link]: #{self.book.goodreads_url} \n" + 
			 	"[author_link]: #{self.book.author_url} \n" + 
			 	"[review_link]: #{self.review_url} \n" + 
			 	"\n\n"
	end
end

class GoodreadsImporter
	def initialize(api_key)
		@api_key = api_key.to_s
	end

	def apiCall(method, needsKey, parameters)
		url = BASE_URL + method

		if needsKey || parameters.length > 0 then 
			url = url + "?"
		end

		needsSep = false
		if needsKey then 
			url = url + "key=#{@api_key}"
			needsSep = true 
		end 

		parameters.each_pair do |key,value|
			if needsSep then 
				url = url + "&"
			end 

			url += "#{CGI.escape(key.to_s)}=#{CGI.escape(value.to_s)}"
			needsSep = true 
		end

		return Net::HTTP.get_response(URI.parse(url)).body
	end

	def listBooks(user_id, number)
		xml_data = self.apiCall(
			'review/list.xml', 
			true, 
			{
				"id" => user_id,
				"sort" => "date_read",
				"order" => "d",
				"per_page" => number,
				"shelf" => "read"
			})

		books = []
		doc = REXML::Document.new(xml_data)

		doc.elements.each('GoodreadsResponse/books/book') do |ele|
			books << GoodreadsBook.new(user_id, ele)
		end

		return books
	end

	def getReview(book)
		xml_data = self.apiCall(
			'review/show_by_user_and_book.xml',
			true,
			{
				"user_id" => book.user_id,
				"book_id" => book.id,
				"include_review_on_work" => "true"
			})
		doc = REXML::Document.new(xml_data)
		
		doc.elements.each('GoodreadsResponse/review') do |ele|
			return GoodreadsReview.new(book, REXML::XPath.match(doc, "/GoodreadsResponse/review")[0]) 
		end

		return nil
	end

	def importReview(book)
		review = getReview(book)
		
		abort("Could not get review") if !review
		
		fileName = CGI.escape("review-" + book.title.downcase.gsub(/\s+/, '-').gsub(/[^0-9a-z]/i, '-') + '.md')
		
		writeFile fileName, review.review_flavoredmarkdown
		#print review.review_flavoredmarkdown
	end

	def writeFile(fileName, content)
		abort("File '#{fileName}' already exists in the current directory.") if File::exists?(fileName)

		File.open(fileName, 'w') {|file| file.write(content)}
		print "\n\nWrote review to #{fileName}\n\n"
	end
end