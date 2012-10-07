# -*- coding: utf-8 -*-

$: << File.dirname(__FILE__)
require 'test_helper'
require 'test/unit'
require 'Fileutils'
require 'date'

#
# localhostにtestdata_generater_for_mysql_testというデータベースを作成し
# rootのパスワードなしでアクセスできるようにしておいてください
#

include TestdataGeneraterForMysql

class TestTestdataGeneraterForMysql < Test::Unit::TestCase

  CNT_BRAND      =  5
  SHOP_PER_BRAND =  6
  USER_PER_SHOP  = 22
  STAMP_PER_USER =  3

  def setup
    disable_progress_bar
    setup_mysql_client :host => "127.0.0.1", :username => "root",:database=>'testdata_generater_for_mysql_test'
    insert_per_rows = 29
    query "DROP TABLE IF EXISTS tests;"
  end

  def assert_count(should_be ,where=nil, message=nil)
    where = where ? "WHERE #{where}" : ''
    where_st = where
    where_st = 'COUNT ALL' if where.size == 0
    count = query("SELECT COUNT(*) AS cnt FROM tests #{where}").first['cnt']
    message = build_message message, "'#{where}' should be #{should_be},but #{count}", where
    assert_block message do
      count == should_be
    end
  end

  def test_2_loops
    # テーブル作成
    query "
CREATE TABLE tests (
  `id`          int(11) NOT NULL auto_increment,
  `brand_id`    int(11) NOT NULL,
  `shop_id`     int(11) NOT NULL,
  `name`        varchar(20) NOT NULL,
  `value1`      int(11) NOT NULL,
  `value2`      int(11) ,
  `value3`      int(11) ,
  `value_nil`   int(11) ,
  `value_func`  varchar(20),
  `value_true`  tinyint(1) ,
  `value_false` tinyint(1) ,
  `value_date`  date ,
  `value_dtime` datetime ,
  `value_time`  datetime ,
  `created_at`  datetime ,
  PRIMARY KEY  (`id`),
  KEY `idx01` USING BTREE (`brand_id`,`shop_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
"

    # データ作成
    loops = [
      [:brand_id, (1..CNT_BRAND)],
      [:shop_id,  (1..SHOP_PER_BRAND)]
    ]
    procs = {
      :brand_id    => Proc.new{|v|v[:brand_id]},
      :shop_id     => Proc.new{|v|v[:shop_id]},
      :name        => Proc.new{|v|"#{v[:brand_id]}_#{v[:shop_id]}'s name"},
      :value1      => Proc.new{rand(10000)},
      :value2      => Proc.new{rand(10000)},
      :value_nil   => Proc.new{nil},
      :value_func  => Proc.new{"CONCAT('My', 'S', 'QL')".to_func},
      :value_true  => Proc.new{true},
      :value_false => Proc.new{false},
      :value_date  => Proc.new{Date.new(2001,2,3)},
      :value_dtime => Proc.new{DateTime.new(2001,2,3,4,35,6)},
      :value_time  => Proc.new{Time.mktime(2001,2,3,4,35,6)},
      :created_at  => Proc.new{'NOW()'.to_func},
    }
    create_rows(
      'tests',
      loops,
      procs
    )

    # 作成データのチェック
    cnt_all = CNT_BRAND * SHOP_PER_BRAND
    assert_count cnt_all
    assert_count SHOP_PER_BRAND, "brand_id = 3"
    assert_count CNT_BRAND,      "shop_id = 3"
    assert_count 0,              "value2 IS NULL"
    assert_count cnt_all,        "value3 IS NULL"
    assert_count cnt_all,        "value_nil IS NULL"
    assert_count cnt_all,        "value_func = 'MySQL'"
    assert_count 0,              "created_at IS NULL"
    assert_count 1,              "name = '1_1''s name'"
    assert_count cnt_all,        "value_true = 1"
    assert_count cnt_all,        "value_false = 0"
    assert_count cnt_all,        "value_date = '2001-02-03'"
    assert_count cnt_all,        "value_dtime = '2001-02-03 04:35:06'"
    assert_count cnt_all,        "value_time = '2001-02-03 04:35:06'"
  end

  def test_4_loops
    # テーブル作成
    query "
CREATE TABLE tests (
  `id`          int(11) NOT NULL auto_increment,
  `brand_id`    int(11) NOT NULL,
  `shop_id`     int(11) NOT NULL,
  `user_id`     int(11) NOT NULL,
  `stamp_id`    int(11) NOT NULL,
  `name`        varchar(20) NULL,
  `value1`      int(11) NOT NULL,
  `value2`      int(11) ,
  `value3`      int(11) ,
  `value_nil`   int(11) ,
  `value_func`  varchar(20),
  `value_true`  tinyint(1) ,
  `value_false` tinyint(1) ,
  `value_date`  date ,
  `value_dtime` datetime ,
  `value_time`  datetime ,
  `created_at`  datetime NULL,
  PRIMARY KEY  (`id`),
  KEY `idx01` USING BTREE (`brand_id`,`shop_id`,`user_id`,`stamp_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
"

    # データ作成
    loops = [
      [:brand_id, (1..CNT_BRAND)],
      [:shop_id,  (1..SHOP_PER_BRAND)],
      [:user_id,  (1..USER_PER_SHOP)],
      [:stamp_id, (1..STAMP_PER_USER)],
    ]
    procs = {
      :brand_id    => Proc.new{|v|v[:brand_id]},
      :shop_id     => Proc.new{|v|v[:shop_id]},
      :user_id     => Proc.new{|v|v[:user_id]},
      :stamp_id    => Proc.new{|v|v[:stamp_id]},
      :name        => Proc.new{|v|"#{v[:brand_id]}_#{v[:shop_id]}_#{v[:user_id]}_#{v[:stamp_id]}'s name"},
      :value1      => Proc.new{rand(10000)},
      :value2      => Proc.new{rand(10000)},
      :value_nil   => Proc.new{nil},
      :value_func  => Proc.new{"CONCAT('My', 'S', 'QL')".to_func},
      :value_true  => Proc.new{true},
      :value_false => Proc.new{false},
      :value_date  => Proc.new{Date.new(2001,2,3)},
      :value_dtime => Proc.new{DateTime.new(2001,2,3,4,35,6)},
      :value_time  => Proc.new{Time.mktime(2001,2,3,4,35,6)},
      :created_at  => Proc.new{'NOW()'.to_func},
    }
    create_rows(
      'tests',
      loops,
      procs
    )

    # 作成データのチェック
    cnt_all = CNT_BRAND * SHOP_PER_BRAND * USER_PER_SHOP * STAMP_PER_USER
    cnt_per_brand = cnt_all / CNT_BRAND
    cnt_per_user  = cnt_all / USER_PER_SHOP
    assert_count cnt_all
    assert_count cnt_per_brand, "brand_id = 3"
    assert_count cnt_per_user,  "user_id = 3"
    assert_count 0,             "value2 IS NULL"
    assert_count cnt_all,       "value3 IS NULL"
    assert_count cnt_all,       "value_nil IS NULL"
    assert_count cnt_all,       "value_func = 'MySQL'"
    assert_count 0,             "created_at IS NULL"
    assert_count 1,             "name = '1_1_1_1''s name'"
    assert_count cnt_all,       "value_true = 1"
    assert_count cnt_all,       "value_false = 0"
    assert_count cnt_all,       "value_date = '2001-02-03'"
    assert_count cnt_all,       "value_dtime = '2001-02-03 04:35:06'"
    assert_count cnt_all,       "value_time = '2001-02-03 04:35:06'"
    row = query("SELECT * FROM tests WHERE name = '1_1_1_1''s name'").first
    assert row['brand_id'] == 1 && row["shop_id"] == 1 && row["user_id"] == 1 && row["stamp_id"] == 1
  end
end
