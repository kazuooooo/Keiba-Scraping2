require "keiba_scraping/version"
require 'nokogiri'
require 'mechanize'


module KeibaScraping
  # 東京 12月の結果ページ(後々もっと広げる)
  URL = 'http://keiba.yahoo.co.jp/schedule/list/2015/?place=5'
  # Race 日付、場所、第何Rか
  class Race < Struct.new(:date, :place, :race_num); end
  # horce 着順、枠番、馬番、人気、オッズ
  class Horce < Struct.new(:ranking, :frame_num, :horce_num, :popularity, :odds); end
  # 日付のページにいる状態
  agent = Mechanize.new
  date_page = agent.get(URL)
  # 各開催名をクリックした後のページ(1)を取得

    # (1) のページそれぞれに対して　 
      # 主なレースをクリックした後のページ(2)を取得
        # (2) のページそれぞれに対して
          #レース結果をスクレイピングして格納
            # csvに突っ込む
end
