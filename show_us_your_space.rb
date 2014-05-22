#! /usr/bin/env ruby

require 'rubygems'
require 'uri'
require 'net/https'
require 'nokogiri'

def hidden_input
  uri = URI("https://www.internetweekny.com/spaces")
  http = Net::HTTP.new(uri.host, uri.port)

  http.read_timeout = 500
  http.use_ssl=true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE

  req = Net::HTTP::Get.new(uri.request_uri)
  resp = http.request(req)

  doc = Nokogiri::HTML(resp.body)
  {
    "authenticity_token" => doc.css("input[name=authenticity_token]").attribute('value').text,
    "utf8" => doc.css("input[name=utf8]").attribute('value').text
  }
end

def vote
  uri = URI("https://www.internetweekny.com/spaces/vote")
  http = Net::HTTP.new(uri.host, uri.port)

  http.read_timeout = 500
  http.use_ssl=true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE

  req = Net::HTTP::Post.new(uri.request_uri)
  req.set_form_data(hidden_input.merge({"vote"=>"12","commit"=>"Vote"}))
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
margin = ARGV[1] ? ARGV[1].to_i : 2
puts "Checking that Animoto is winning by #{margin}"

if results["Animoto"] > results["Adcade"] + margin
  puts "Animoto is winning"
else
  threads = ARGV[0].to_i.times.map do |i|
    Thread.new do
      begin
        report(vote().body)
      rescue Exception => e
        puts "Thread #{i} died because of exception: #{e.message}"
      end
    end
  end

  loop do
    sleep 1

    statuses = threads.inject({}) do |statuses, t|
      statuses[t.status] ||= 0
      statuses[t.status] += 1
      statuses
    end.to_a

    puts "THREADS STATUS: #{statuses.map{|pair| "#{pair[0]}:#{pair[1]}"}.join(" ")}"

    break if threads.reject{|t| t.status.nil? || t.status == false}.empty?
  end
end

