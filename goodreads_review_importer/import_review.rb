#!/usr/bin/ruby

require 'GoodreadsImporter.rb'
require 'api_keys.rb'

###############
# NOTE: This script requires a file called 'api_keys.rb' to be available (probably just in this same directory).
# This file should define a single global variable called API_KEY which is a string version of your good reads API key.
# This file is not included in this public repository for obvious reasons. 
#
###############

USER_ID = '369276'

importer = GoodreadsImporter.new(API_KEY)

#url = BASE_URL + "review/list.xml?key=#{@api_key}&id=#{user_id}&sort=date_read&order=d&per_page=#{number}&shelf=read"
# importer.apiCall("review/list.xml", true, {"id" => USER_ID, "sort" => "date_read", "order" => "d", "per_page" => "5", "self" => "read"})
# abort("done")
books = importer.listBooks(USER_ID, 5)

if books.count <= 0 then
	abort("Unable to find any reviews from Goodreads\n")
end

books.each_with_index do |book, index|
	print "#{index}: #{book.title}\n"
end

STDOUT.flush()
print "\nSelect Review To Import [0]: "
selected_review = gets.chomp

if selected_review.to_s.empty? then 
	selected_review = "0"
end

if !(selected_review =~ /^[0-9]+$/) then
	abort("Unable to parse selection as integer")
end

selected_review = Integer(selected_review)
if !(selected_review >= 0 && selected_review < books.count) then
	abort("Selection was not a valid choice")
end

importer.importReview(books[selected_review])