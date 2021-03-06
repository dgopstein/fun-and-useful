#!/usr/bin/env ruby
require 'open-uri'
require 'nokogiri'
require 'deep_enumerable'
require 'pp'

# https://www.tiobe.com/tiobe-index/
languages = [
'Java', 'C', 'C++', 'C#', 'Python', 'Visual Basic .NET', 'PHP', 'JavaScript',
'Delphi/Object Pascal', 'Swift', 'Perl', 'Ruby', 'Assembly', 'R',
'Visual Basic', 'Objective-C', 'Go', 'MATLAB', 'PL/SQL', 'Scratch', 'SAS',
'D', 'Dart', 'ABAP', 'COBOL', 'Ada', 'Fortran', 'Transact-SQL', 'Lua', 'Scala',
'Logo', 'F#', 'Lisp', 'LabVIEW', 'Prolog', 'Haskell', 'Scheme', 'Groovy',
'RPG (OS/400)', 'Apex', 'Erlang', 'MQL4', 'Rust', 'Bash', 'Ladder Logic', 'Q',
'Julia', 'Alice', 'VHDL', 'Awk']

def search_google(query)
  wait_time = (1.2 + 3*Random.rand()).round(2)
  query_str = URI::encode(query)
  query_url = "http://www.google.com/search?hl=en&q=#{query_str}"
  puts "Waiting #{wait_time} seconds, then fetching: #{query_url}"
  sleep(wait_time)
  response = open(query_url, 'User-Agent' => 'Chrome')
  if response.status.first != "200"
    puts "Error fetching: #{query_url} - #{response.status}"
  end
  response.read
end

def cache_file(key)
  File.join('cache', key.gsub(/[ \/]/, '_')+".html")
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

def search_language(lang)
  query_components =
   [[lang, "programming language", nil],
    [lang, "programming language", :fun],
    [lang, "programming language", :powerful]]

  query_components.map do |(lang, filler, modifier)|
    query_str = "\"#{lang} #{filler}\" #{modifier}".strip

    [[lang, modifier], maybe_search_google(query_str)]
  end
end

def n_results(results_html)
  doc = Nokogiri::HTML(results_html)
  text = doc.xpath("//div[@id='resultStats']").text
  text.gsub(/\D/, '').to_i
end

def aggregate_results(languages)
  individual_counts =
    languages.map{|lang| search_language(lang)}.flatten(1)
             .map{|(query, html)| [query, n_results(html)]}

  individual_counts.map{|(lang, type), count| {lang => {(type || :all) => count}}}
    .inject({}){|a, b| a.merge(b) {|key, a, b| a.merge(b)} }
end

def normalize_results(agg_results)
  agg_results.shallow_map_values do |counts|
    {all: counts[:all],
     fun: (counts[:fun] / counts[:all].to_f).round(3),
     powerful: (counts[:powerful] / counts[:all].to_f).round(3)}
  end
end

def write_agg_csv(aggs)
  aggs.map{|k,h| [k, h[:all], h[:fun], h[:powerful]].join(",")}.join("\n")
end

puts write_agg_csv(normalize_results(aggregate_results(languages)))

