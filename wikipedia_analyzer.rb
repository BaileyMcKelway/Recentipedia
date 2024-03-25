#!/usr/bin/env ruby

require 'httparty'
require 'json'
require 'cgi'
require 'net/http'
require 'uri'


# Extracts birth year from the given content using a regular expression
def extract_birth_year(content)
  return nil if content.nil? || content.empty?

  match = content.match(/\((?:born\s+)?(\d{4})|(\d{4})\s?–|(\d{4}) in/)
  match&.captures&.compact&.first
end

# Parses the response from the OpenAI API and returns separate lists for people, sports, and other titles
def parse_response(response)
  sections = response.split("\n")
  people_titles = sections.find { |section| section.start_with?('People:') }&.gsub('People: ', '')&.split(', ') || []
  sports_titles = sections.find { |section| section.start_with?('Sports:') }&.gsub('Sports: ', '')&.split(', ') || []
  other_titles = sections.find { |section| section.start_with?('Other:') }&.gsub('Other: ', '')&.split(', ') || []

  [people_titles, sports_titles, other_titles]
end

# Classifies titles using the OpenAI API
def classify_titles(titles, openai_api_key)
  uri = URI.parse('https://api.openai.com/v1/chat/completions')
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true

  request = Net::HTTP::Post.new(uri.request_uri)
  request['Content-Type'] = 'application/json'
  request['Authorization'] = "Bearer #{openai_api_key}"
  request.body = JSON.dump(
    model: 'gpt-4',
    messages: [
      {
        "role": "user",
        "content": "Here is a list of titles. Return three separate lists, people, sports, and other. If a title is not a person or related to sports it should go in other.\nList: Dan John, Duarte Alves, Mike Wenstrup, Raffaello della Rovere, Franziska Stömmer, Deborah Kent, Rose Koller, Hanna Klose-Greger, 2024 in paralympic sports, Sean Bagniewski, Ulrike Kindl, Sidonie von Krosigk, Massivo, Douce Apocalypse, Pasja (2002), Silver, Platinum & Gold, American Cinema Editors Awards 1964"
      },
      {
        "role": "assistant",
        "content": "People: Dan John, Duarte Alves, Mike Wenstrup, Raffaello della Rovere, Franziska Stömmer, Deborah Kent, Rose Koller, Hanna Klose-Greger, Sean Bagniewski, Ulrike Kindl, Sidonie von Krosigk\nSports: 2024 in paralympic sports\nOther: Massivo, Douce Apocalypse, Pasja (2002), Silver, Platinum & Gold, American Cinema Editors Awards 1964"
      },
      {
        "role": "user",
        "content": "Here is a list of titles. Return three separate lists, people, sports, and other. If a title is not a person or related to sports it should go in other.\nList:#{titles.join(", ")}"
      }
    ],
    temperature: 0.21,
    max_tokens: 1024
  )

  response = http.request(request)
  JSON.parse(response.body)['choices'][0]['message']['content']
end

# Fetches the description of a Wikipedia article
def fetch_article_content(title)
  url = 'https://en.wikipedia.org/w/api.php'
  params = {
    action: 'query',
    prop: 'extracts',
    titles: title,
    exintro: true,
    format: 'json'
  }
  response = HTTParty.get(url, query: params)
  page = response.parsed_response.dig('query', 'pages').values.first
  page['extract']
end

# Fetches recently changed articles from Wikipedia
def fetch_new_articles
  url = 'https://en.wikipedia.org/w/api.php'
  params = {
    action: 'query',
    list: 'recentchanges',
    rctype: 'new',
    rcnamespace: '0',
    rclimit: '500',
    rcprop: 'title|ids|sizes|user|timestamp',
    format: 'json',
    rcstart: (Time.now.utc - (60 * 60)).strftime('%Y%m%d%H%M%S')
  }
  response = HTTParty.get(url, query: params)
  JSON.parse(response.body)
end

# Constructs URLs for Wikipedia articles and their diffs
def construct_links(change)
  title = CGI.escape(change['title'].gsub(' ', '_'))
  {
    article_url: "https://en.wikipedia.org/wiki/#{title}",
    diff_url: "https://en.wikipedia.org/w/index.php?title=#{title}&diff=#{change['revid']}&oldid=#{change['old_revid']}",
    user_contribs_url: "https://en.wikipedia.org/wiki/Special:Contributions/#{CGI.escape(change['user'])}"
  }
end


if __FILE__ == $0
  if ARGV.empty?
    puts "Usage: #{$0} <openai_api_key>"
    exit 1
  end

  openai_api_key = ARGV[0]

  new_articles = fetch_new_articles['query']['recentchanges']
  new_articles.each { |article| article.merge!(construct_links(article)) }
  significant_articles = new_articles.select { |change| (change['newlen'] - change['oldlen']).abs > 3684 }
  titles = significant_articles.map { |article| article['title'] }
  response = classify_titles(titles, openai_api_key)

  people_titles, sports_titles, other_titles = parse_response(response)
  filtered_articles = significant_articles.select do |article|
    title = article['title']
    if other_titles.include?(title)
      true
    elsif people_titles.include?(title)
      content = fetch_article_content(title)
      birth_year = extract_birth_year(content)
      birth_year && birth_year.to_i < 1900
    else
      false
    end
  end
  puts "Articles:"
  filtered_articles.each_with_index do |article, index|
    puts "#{index + 1}. #{article['title']} - #{article[:article_url]}"
  end

  puts "\n"
end
