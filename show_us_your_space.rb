#! /usr/bin/env ruby

require 'rubygems'
require 'uri'
require 'net/https'
require 'nokogiri'

def vote
  uri = URI("https://www.internetweekny.com/spaces/vote")
  http = Net::HTTP.new(uri.host, uri.port)

  http.use_ssl=true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE

  req = Net::HTTP::Post.new(uri.request_uri)
  req.set_form_data({"vote"=>"12","commit"=>"Vote"})
  http.request(req)
end

def report html
  doc = Nokogiri::HTML(html)
  result = Hash[doc.css("li.space").map do |li|
    team = li.css("img").attribute('alt').to_s
    value = li.css("span.percentage").text.gsub('%','').to_i
    [team, value]
  end]
  puts result.to_a.sort_by{|pair| pair[1]}.reverse.map{|pair| "#{pair[0]}:#{pair[1]}%"}.join(" ")
  result
end

results = report(vote().body)

if results["Animoto"] > results["Adcade"] + 2
  puts "Animoto is winning"
else
  threads = ARGV[0].to_i.times.map do
    Thread.new do
      report(vote().body)
    end
  end

  while(!threads.reject{|t| t.status.nil? || t.status == false}.empty?) do
    statuses = threads.inject({}) do |statuses, t|
      statuses[t.status] ||= 0
      statuses[t.status] += 1
      statuses
    end.to_a
    puts "THREADS STATUS: #{statuses.map{|pair| "#{pair[0]}:#{pair[1]}"}.join(" ")}"

    sleep 1
  end
end

