#! /usr/bin/env ruby

require 'rubygems'
require './vote'

results = report(vote().body)
margin = ARGV[1] ? ARGV[1].to_i : 2
puts "Checking that Animoto is winning by #{margin}"

if results["Animoto"] > results["Adcade"] + margin
  puts "Animoto is winning"
else
  threads = ARGV[0].to_i.times.map do |i|
    Thread.new do
      begin
        Timeout::timeout(120) do
          report(vote().body)
        end
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

