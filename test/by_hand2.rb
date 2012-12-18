# -*- coding: utf-8 -*-

$: << File.dirname(__FILE__) + '/../lib'
require 'testdata_generater_for_mysql'

require 'benchmark'
require 'json'

#
# hogehogableってテーブルを作ります
# その際、タイプを指定するカラムを文字列or数値でどれぐらいの開きがあるのか？
# の検証です
#

include TestdataGeneraterForMysql
setup_mysql_client(
  :host => "127.0.0.1",
  :username => "root",
  :database=>'testdata_generater_for_mysql_test')

insert_per_rows 200
#hide_progress_bar

TABLE  = 'load_table_test'

# 100万レコード保持
#CNT_PARENT = 100_000
#CHANGE_POINT = 50_000

CNT_PARENT = 400
CHANGE_POINT = 200

def varchar_col_value(i)
  i.to_s.rjust(10,'0')
end

def create_data
  return if load_table(TABLE)
  query "DROP TABLE IF EXISTS #{TABLE};"
  query "
CREATE TABLE #{TABLE} (
  `id`          bigint(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `json`        text NOT NULL,
  `created_at`  datetime ,
  PRIMARY KEY  (`id`),
  INDEX `idx01` (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
"

  # ループランダムで回す(メモリを食います(100万レコードで500M〜))
  #random_loop
  loops = [
    [:parent_id, (1..CNT_PARENT)],
  ]

  st1 = 'a' * 60
  st2 = 'b' * 60
  st3 = 'あ' * 60

  today = Time.now
  yesterday = (Time.now - 24 * 60 * 60)

  procs = {
    :json       => proc{|v|
        hash = {}
        (1..20).each do |i|
          hash[i] = rand(100)
        end
        hash[1] = v[:parent_id]
        hash['st1'] = st1
        hash['st2'] = st2
        hash['st3'] = st3

        hash.to_json
      },
    :created_at => proc{|v| v[:parent_id] < CHANGE_POINT ? 'date_sub(now() , interval 1 day)'.to_func : 'NOW()'.to_func},
  }

  create_rows(
    "#{TABLE}",
    loops,
    procs
  )

  save_table(TABLE)
end

create_data
