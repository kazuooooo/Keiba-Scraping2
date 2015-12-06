require "keiba_scraping/version"
require 'nokogiri'
require 'mechanize'
require 'webmock'
require 'vcr'
require 'pry'
require 'csv'

VCR.configure do |config|
  config.cassette_library_dir = "vcr/vcr_cassettes"
  config.hook_into :webmock
end

module KeibaScraping
  # Race 日付、場所、第何Rか
  class Race < Struct.new(:date, :place, :race_num); end
  # horce 着順、枠番、馬番、人気、オッズ
  class Horce < Struct.new(:ranking, :frame_num, :horce_num, :popularity, :odds); end

  (1..10).to_a.each do |place_num|
    VCR.use_cassette("keiba_scraping", :record => :new_episodes) do
      # 東京 12月の結果ページ(後々もっと広げる)
      p "start place" << place_num.to_s
      url = "http://keiba.yahoo.co.jp/schedule/list/2015/?place=" << place_num.to_s

       
        # URLにいる状態を作る
      #def process_do
        agent = Mechanize.new
        date_list_page = agent.get(url)

        # 各開催名をクリックした後のページ(1)を取得
        # リンクを取得
        race_list_links = date_list_page.links.select do |link| 
                            /.回.*日/ === link.text
                          end
        race_list_pages = race_list_links.map{ |link| begin link.click rescue retry end}
        #binding.pry
        # (1) のページそれぞれに対して
        race_list_pages.each do |race_list_page|
          # 主なレースをクリックした後のページ(2)を取得
          race_links = race_list_page.links.select { |link| 
                         /^\/race\/result/ === link.href 
                       }
          race_pages = race_links.map{ |link| begin link.click rescue retry end }
            # (2) のページそれぞれに対して
            race_pages.each do |race_page|
              html = Nokogiri::HTML(race_page.body)
              # Race情報を取得
              title_text = html.css('#raceTitDay').text
              title_text_array = title_text.gsub(" ","").split("|")
              # 日付
              date = title_text_array[0]
              # 場所
              place = title_text_array[1][2,2]
              # 第何Rか
              race_num = html.css('#raceNo').text[0,1].to_i
              race_obj = Race.new(date, place, race_num)
              # horce情報を取得
              horces = html.css('#resultLs tr:not(:first-child)').css('tr:not(:last-child)')
              horces.each do |horce|
                #binding.pry
                ranking = horce.at_css('td.txC:nth-of-type(1)').inner_text.gsub(/[\r\n]/,"").to_i
                frame_num = horce.at_css('td.txC:nth-of-type(2)').inner_text.gsub(/[\r\n]/,"").to_i
                horce_num = horce.at_css('td.txC:nth-of-type(3)').inner_text.gsub(/[\r\n]/,"").to_i
                popularity = horce.at_css("td.txC.fntS").inner_text.to_i
                odds = horce.at_css("td.fntS:nth-of-type(6)").inner_text.to_f
                horce_obj = Horce.new(
                                      ranking,
                                      frame_num,
                                      horce_num,
                                      popularity,
                                      odds
                                      )
                CSV.open("test.csv","a") do |csv|
                  csv << [
                          race_obj.date, 
                          race_obj.place, 
                          race_obj.race_num, 
                          horce_obj.ranking,
                          horce_obj.frame_num,
                          horce_obj.horce_num,
                          horce_obj.popularity,
                          horce_obj.odds,
                         ]
                end
              end
            end
        end
    end
  end
end
