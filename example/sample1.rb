# -*- coding: utf-8 -*-

require 'rubygems'
require 'testdata_generater_for_mysql'

#
# localhostにtestdata_generater_for_mysql_testというデータベースを作成し
# rootのパスワードなしでアクセスできるようにしておいてください
#

include TestdataGeneraterForMysql

CNT_BRAND      =  5
SHOP_PER_BRAND =  6
USER_PER_SHOP  = 22

client = setup_mysql_client :host => "127.0.0.1", :username => "root",:database=>'testdata_generater_for_mysql_test'
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
loops = [
  [:brand_id, (1..CNT_BRAND)],
  [:shop_id,  (1..SHOP_PER_BRAND)],
  ['user_id', (1..USER_PER_SHOP)] # 文字列でキーを指定も
]
#
# 次に各列の処理を設定します。
# データはハッシュにて設定します。設定したいカラムの名前をkeyにて設定、
# valueはProcインスタンスにて設定します。Procのイニシャライザのブロック引数に
# loopsで設定した値が引き渡されます(上記サンプルのso_somethingのところの値が
# ハッシュにて引き渡されます)。
# 基本的にvalueは自動的にエスケープされシングルクォーテーションで囲まれます。
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
  :value_func  => Proc.new{"CONCAT('My', 'S', 'QL')".to_func},
  :value_true  => Proc.new{true},
  :value_time  => Proc.new{Time.mktime(2001,2,3,4,35,6)},
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
puts '=' * 60
