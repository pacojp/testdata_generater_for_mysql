# -*- coding: utf-8 -*-

$: << File.dirname(__FILE__)
require 'test_helper'
require 'test/unit'
require 'Fileutils'

#
# localhostにtestdata_generater_for_mysql_testというデータベースを作成し
# rootのパスワードなしでアクセスできるようにしておいてください
#

include TestdataGeneraterForMysql

class TestTestdataGeneraterForMysql < Test::Unit::TestCase

  BRAND_COUNT     = 13
  USER_PER_BRAND  = 10_000
  
  def count(where=nil)
    where = where ? " WHERE #{where} " : ''
    query("SELECT COUNT(*) AS cnt FROM tests #{where}").first['cnt']
  end

  def test
    disable_progress_bar
    setup_mysql_settings(:host => "127.0.0.1", :username => "root",:database=>'testdata_generater_for_mysql_test')
    insert_per_rows = 1000

    # テーブル作成
    query "DROP TABLE IF EXISTS tests;"
    query "
CREATE TABLE tests (
  `id` int(11) NOT NULL auto_increment,
  `brand_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `name` varchar(20) NULL,
  `value1` int(11) NOT NULL,
  `value2` int(11) ,
  `value3` int(11) ,
  `value_nil` int(11) ,
  `value_true` tinyint(1) ,
  `value_false` tinyint(1) ,
  `created_at` datetime NULL,
  PRIMARY KEY  (`id`),
  KEY `idx01` USING BTREE (`brand_id`,`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
"

    # データ作成
    loops = [
      [:brand_id,(1..BRAND_COUNT)],
      [:user_id, (1..USER_PER_BRAND)]
    ]
    procs = {
      :brand_id    => Proc.new{|v|v[:brand_id]},
      :user_id     => Proc.new{|v|v[:user_id]},
      :name        => Proc.new{|v|"#{v[:brand_id]}_#{v[:user_id]}_name"},
      :value1      => Proc.new{rand(10000)},
      :value2      => Proc.new{rand(10000)},
      :value_nil   => Proc.new{nil},
      :value_true  => Proc.new{true},
      :value_false => Proc.new{false},
      :created_at  => Proc.new{'NOW()'},
    }
    create_rows(
      'tests',
      loops,
      procs
    )
    
    # 作成データのチェック
    cnt_all = BRAND_COUNT * USER_PER_BRAND
    assert_equal cnt_all,       count
    assert_equal USER_PER_BRAND,count "brand_id = 3"
    assert_equal BRAND_COUNT,   count "user_id = 3"
    assert_equal 0,             count "value2 IS NULL"
    assert_equal cnt_all,       count "value3 IS NULL"
    assert_equal cnt_all,       count "value_nil IS NULL"
    assert_equal 0,             count "created_at IS NULL"
    assert_equal 1,             count "name = '1_1_name"
    assert_equal cnt_all,       count "value_true = 1"
    assert_equal cnt_all,       count "value_false = 0"
  end
end
