#!/usr/bin/env ruby
# coding: utf-8

bad = " "

require 'csv'

require 'nokogiri'
require 'open-uri'

require 'cgi'
require 'date'

base = 'http://www.euroleague.net'

team_base = 'http://www.euroleague.net/competition/teams/showteam'

boxscore_base = 'http://www.euroleague.net/main/results/showgame?gamecode=164&seasoncode=E2013#!boxscore'

score_xpath = '//*[@id="games"]//tr'

first_year = 2014
last_year = 2014

if (first_year==last_year)
  results = CSV.open("csv/games_#{first_year}.csv","w")
else
  results = CSV.open("csv/games_#{first_year}-#{last_year}.csv","w")
end

team_file = CSV.read('csv/teams_2014.csv',{:headers => TRUE})

team_file.each do |team|

  year = team["year"]
  team_id = team["team_id"]

  url = "#{team_base}?clubcode=#{team_id}&seasoncode=E#{year}"

  print "#{team_id} - #{year}\n"

  begin
    doc = Nokogiri::HTML(open(url))
  rescue
    print "  - not found\n"
    next
    #retry
  end

  doc.xpath(score_xpath).each do |tr|
    row = [year,team_id]
    tr.xpath("td").each_with_index do |td,i|

      raw = td.text.strip
      case i
      when 2
        a = td.xpath('a').first
        href = base+a.attribute('href').value
        ps = CGI::parse(href.split("?")[1])
        gamecode = ps["gamecode"][0]

        if (raw.start_with?('vs'))
          text = raw[2..-1].strip.sub("\u00A0","")
          row += ['home',text,raw,href,gamecode]
        else
          text = raw[2..-1].strip.sub("\u00A0","")
          row += ['away',text,raw,href,gamecode]
        end

      when 3

        if not(raw=='')
          scores = raw.split('-')
          home_score = scores[0].strip rescue nil
          away_score = scores[1].strip rescue nil
          row += [home_score,away_score]
        else
          row += [nil,nil]
        end

      else
        row += [raw]
      end
    end
    if not(row[3]=="")
      results << row
    end
  end

end


results.close
