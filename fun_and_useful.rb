#!/usr/bin/env ruby
require 'open-uri'
require 'nokogiri'

def search_google(query)
  response = open('http://www.google.com/search?hl=en&q=time', 'User-Agent' => 'Chrome').read
end

def n_results(results_html)
  doc = Nokogiri::HTML(results_html)
  doc.xpath("//div[@id='resultStats']").text
end

def cache_file(key)
  File.join('cache', key.gsub(/ /, '_')+".html")
end

def write_cache(key, data)
  FileUtils.mkdir_p('cache')

  File.write(cache_file(key), data)
end

def read_cache(key)
  File.exists?(cache_file(key)) and File.read(cache_file(key))
end

def maybe_search_google(query)
  cache_data = read_cache(query)
  if (cache_data)
    cache_data
  else
    google_data = search_google(query)
    write_cache(query, google_data)
    google_data
  end
end

maybe_search_google("clojure language fun")
