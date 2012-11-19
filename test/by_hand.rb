# -*- coding: utf-8 -*-

$: << File.dirname(__FILE__) + '/../lib'
require 'testdata_generater_for_mysql'

#
# データ作成は一度
# テストはちょこちょこ更新して結果を調べたいって時は
# データ作成ブロックをgenerate do テストブロックをtest do として作成。
# スクリプト実行時に test_only or test or t とスクリプトの後の指定すれば
# テストのみ実行します
#
# ex.データ作成時
# sample2.rb
#
# ex.テストのみ再実行
# sample2.rb test
#

include TestdataGeneraterForMysql

setup_mysql_client :host => "127.0.0.1", :username => "root",:database=>'testdata_generater_for_mysql_test'

# 定数
CNT_BRAND      = 5
SHOP_PER_BRAND = 10
USER_PER_SHOP  = 203

generate do
  # マルチプルインサートの実行単位を指定します（以下だと200行ずつインサート実行。defaultは100）
  insert_per_rows 200
  # プログレスバーを非表示にしたければ以下をコメントアウト
  #hide_progress_bar

  # 取り敢えず必要なテーブルを作成します(すでに存在する場合は消します)
  query "DROP TABLE IF EXISTS tests;"
  query "
CREATE TABLE tests (
  `id`          int(11) NOT NULL auto_increment,
  `brand_id`    int(11) NOT NULL,
  `shop_id`     int(11) NOT NULL,
  `user_id`     int(11) NOT NULL,
  `name`        varchar(20) NOT NULL,
  `value1`      int(11) NOT NULL,
  `value_nil`   int(11) ,
  `value_func`  varchar(20),
  `value_true`  tinyint(1) ,
  `value_time`  datetime ,
  `created_at`  datetime ,
  PRIMARY KEY  (`id`),
  KEY `idx01` USING BTREE (`brand_id`,`shop_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
"

  loops = [
    [:brand_id, (1..CNT_BRAND)],
    [:shop_id,  (1..SHOP_PER_BRAND)],
    ['user_id', (1..USER_PER_SHOP)] # 文字列でキーを指定も
  ]

  procs = {
    :brand_id    => proc{|v|v[:brand_id]},
    :shop_id     => proc{|v|v[:shop_id]},
    :user_id     => proc{|v|v['user_id']},
    :name        => proc{|v|"#{v[:brand_id]}_#{v[:shop_id]}_#{v['user_id']}'s name"},
    :value1      => proc{rand(10000)},
    :value_nil   => proc{nil},
    :value_func  => proc{"CONCAT('My', 'S', 'QL')".to_func}, #関数指定時はString#to_funcで
    :value_true  => proc{true}, # true は 1 false は 0
    :value_time  => proc{Time.mktime(2001,2,3,4,35,6)}, # Time,DateTime,Date
    :created_at  => proc{'NOW()'.to_func},
  }

  create_rows(
    'tests',
    loops,
    procs
  )
end

test do
  puts '=' * 60
  puts query("SELECT count(id) AS cnt FROM tests").first['cnt'].to_s + "rows created"
  puts 'sample:'
  p query("SELECT * FROM tests WHERE brand_id = #{CNT_BRAND} AND shop_id = #{SHOP_PER_BRAND} AND user_id = #{USER_PER_SHOP}").first
end
