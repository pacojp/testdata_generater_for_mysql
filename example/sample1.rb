# -*- coding: utf-8 -*-

require 'rubygems'
require 'testdata_generater_for_mysql'

#
# localhostにtestdata_generater_for_mysql_testというデータベースを作成し
# rootのパスワードなしでアクセスできるようにしてあるとして
#

# 取り敢えずおまじない
include TestdataGeneraterForMysql

# データベースへのアクセス情報を設定します
setup_mysql_client :host => "127.0.0.1", :username => "root",:database=>'testdata_generater_for_mysql_test'
# マルチプルインサートの実行単位を指定します
insert_per_rows = 200

# 取り敢えず必要なテーブルを再作成します
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

#
# ■データ作成
#
# まずはループ情報を設定します。
# テストデータを作る際は以下な感じで行うと思いますが
#
# (1..10).each do |brand_id|
#   (1..3).each do |shop_id|
#     (1..15).each do |user_id|
#       # do_someting here with brand_id,show_id,user_id
#     end
#   end
# end
#
# これを以下で表現しています。
#
CNT_BRAND      =    21
SHOP_PER_BRAND =    15
USER_PER_SHOP  = 1_003
loops = [
  [:brand_id, (1..CNT_BRAND)],
  [:shop_id,  (1..SHOP_PER_BRAND)],
  ['user_id', (1..USER_PER_SHOP)] # 文字列でキーを指定も
]
#
# 次に各列の処理を設定します。
# データはハッシュにて設定します。設定したいカラムの名前をkeyにて設定、
# valueはProcインスタンスにて設定します。Procのイニシャライザのブロック引数に
# loopsで設定した値が引き渡されます(上記ループ解説の# do_somethingの箇所の値が
# ハッシュにて引き渡されます)。
# 基本的にvalueは実行時にエスケープされシングルクォーテーションで囲まれます。
# 「NOW()」等関数を指定したい場合は"NOW()".to_funcと指定すると値にエスケープ及び
# シングルクォーテーションでの囲みがかからなくなります
#
procs = {
  :brand_id    => Proc.new{|v|v[:brand_id]},
  :shop_id     => Proc.new{|v|v[:shop_id]},
  :user_id     => Proc.new{|v|v['user_id']},
  :name        => Proc.new{|v|"#{v[:brand_id]}_#{v[:shop_id]}_#{v['user_id']}'s name"},
  :value1      => Proc.new{rand(10000)},
  :value_nil   => Proc.new{nil},
  :value_func  => Proc.new{"CONCAT('My', 'S', 'QL')".to_func}, #関数指定時はString#to_funcで
  :value_true  => Proc.new{true}, # true は 1 false は 0
  :value_time  => Proc.new{Time.mktime(2001,2,3,4,35,6)}, # Time,DateTime,Date
  :created_at  => Proc.new{'NOW()'.to_func},
}
#
# 実際にテストデータを作成します
# 引数はテーブル名、ループ、列に対する処理、になります
#
create_rows(
  'tests',
  loops,
  procs
)


# 以下作成結果のサンプルを出力しています
puts '=' * 60
puts query("SELECT count(id) AS cnt FROM tests").first['cnt'].to_s + "rows created"
puts 'sample:'
p query("SELECT * FROM tests WHERE brand_id = #{CNT_BRAND} AND shop_id = #{SHOP_PER_BRAND} AND user_id = #{USER_PER_SHOP}").first

__END__

出力結果は以下な感じになります

$ ruby example/sample1.rb
================   create rows for tests   =================
100% |oooooooooooooooooooooooooooooooooooo| Time:   0:00:23
============================================================
315945rows created
sample:
{"id"=>315945, "brand_id"=>21, "shop_id"=>15, "user_id"=>1003, "name"=>"21_15_1003's name", "value1"=>6704, "value_nil"=>nil, "value_func"=>"MySQL", "value_true"=>1, "value_time"=>2001-02-03 04:35:06 +0900, "created_at"=>2012-10-07 16:06:13 +0900}

