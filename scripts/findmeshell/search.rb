require "faraday"
require "curb"
require "thread"
#require "socksify"
#require 'socksify/http'

class Search
  attr_accessor :url, :tor
  def initilize()
    @url = url
    @tor = tor
  end
  
  def start(url, tor = false)
    @conn = Faraday.new(:url => url) do |faraday|
    faraday.request  :url_encoded             # form-encode POST params
    faraday.response :logger                  # logs results to STDOUT
    faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
    #faraday.adapter  :em_http                 # make requests with http
    faraday.headers[:useragent] = "Mozilla/4.0" #to make the request maybe not get blocked
    #if tor == "true"                          # put requests through socks4 if desired
    #faraday.proxy "http://localhost:9150"
    #end
    end
  end
  
  def response(url)
    begin
    @conn.get "#{url}"
    rescue Faraday::ConnectionFailed
    end
  end
end

def success?(arg, *status)
  if ["#{status.join(', ')}"].include? arg.status
    return true
  else
    return false
  end
end

puts "URL?"
url = gets.chomp
  url.gsub!(/(.*)(\/)(.*)/, '')
  unless url[/\Ahttp:\/\//] || url[/\Ahttps:\/\//]
    url = "http://#{url}"
  end
target = Search.new()
target.start("#{url}")
#puts "tor? [true/false]"
#tor = gets.chomp
puts "Search recursively? [y/n]"
rec = gets.chomp
puts ""

puts "Attempting to determine CMS"
puts ""

#logic to try and determine if the website is running a CMS. I know, it's not elegant...
t=1
while t < 4
  case t
  when 1
    response = target.response('wp-includes/')
    if success?(response, 200, 401, 403, 301, 302)
      puts "This appears to be a Wordpress site, tailoring scan to Wordpress"
      puts ""
      file = "wordpressdirs.txt"
      t = 5
    else
      t += 1
    end
  when 2
    response = target.response('wp-admin/')
    if success?(response, 200, 401, 403, 301, 302)
      puts "This appears to be a Wordpress site, tailoring scan to Wordpress"
      puts ""
      file = "wordpressdirs.txt"
      t = 5
    else
      t += 1
    end
  when 3
    response = target.response('joomla.xml')
    if success?(response, 200, 401, 403, 301, 302)
      puts "This appears to be a Joomla site, tailoring scan to Joomla"
      puts ""
      file = "joomladirs.txt"
      t = 5
    else
      t += 1
    end
  when 4
    response = target.response('templates/')
    if success?(response, 200, 401, 403, 301, 302)
      puts "This appears to be a Joomla site, tailoring scan to Joomla"
      puts ""
      file = "joomladirs.txt"
      t = 5
    else
      t += 1
    end
  end
end

#set the file type based on the above results
if file == "joomladirs.txt" || file == "wordpressdirs.txt"
  puts "Press enter to continue..."
  puts ""
  wait = gets.chomp
else
  if rec == "n"
    file = "shells.txt"
  else
    file = "shellsdir.txt"
  end
  puts "No CMS indicators found, press enter to continue..."
  puts ""
  wait = gets.chomp
end

puts "Starting Scans"
puts ""

#set up multithreading
ln = File.foreach("#{file}").count
per_process = ln/5

paths = Array.new() #we need to temporarily store any paths we find if doing a CMS-specific scan

#scan based on the source determination made above
File.foreach("#{file}").with_index do |line|
  res = "#{url}#{line}"
  line = line.chomp
  response = target.response("#{line}")
    if success?(response, 200)
      unless file == "shellsdir.txt"
        paths << line
      end
      File.open("results.txt", 'a') do |result|
        result.puts res
      end
    end
end

#if there was a CMS specific scan, we now need to see if there are any shells for any of the found directories.
unless file == "shellsdir.txt"
  path.each { |x|
    target = x
  File.foreach("shells.txt").with_index do |line|
  res = "#{x}#{line}"
  line = line.chomp
  begin
  response = target.response("#{line}")
    if success?(response, 200)
      File.open("results.txt", 'a') do |result|
        result.puts res
      end
    end
  rescue Faraday::ConnectionFailed
  end
  end
  }
end
