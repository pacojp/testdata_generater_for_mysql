# -*- coding: utf-8 -*-

require 'rubygems'
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
hide_progress_bar

WITH_PKEY  = 'delete_with_pkey'
WITHOUT_PKEY  = 'delete_without_pkey'

# 100万レコード保持
#CNT_PARENT = 100_000
#CHANGE_POINT = 50_000

CNT_PARENT = 400_000
#CHANGE_POINT = 200_000 # インデックスが効かないサイズ（delete 関係ないけど）
CHANGE_POINT = 20_000 # インデックスが効くサイズ(delete 関係ないけど)

CREATE_TABLE_WITH_PKEY = "
CREATE TABLE #{WITH_PKEY} (
  `id`          bigint(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `json`        text NOT NULL,
  `created_at`  datetime ,
  PRIMARY KEY  (`id`),
  INDEX `idx01` (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
"
CREATE_TABLE_WITHOUT_PKEY = "
CREATE TABLE #{WITHOUT_PKEY} (
  `json`        text NOT NULL,
  `created_at`  datetime ,
  INDEX `idx01` (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
"

def varchar_col_value(i)
  i.to_s.rjust(10,'0')
end

def create_data
  return if load_table(WITH_PKEY) && load_table(WITHOUT_PKEY)
  query "DROP TABLE IF EXISTS #{WITH_PKEY};"
  query CREATE_TABLE_WITH_PKEY

  query "DROP TABLE IF EXISTS #{WITHOUT_PKEY};"
  query CREATE_TABLE_WITHOUT_PKEY

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
    "#{WITH_PKEY}",
    loops,
    procs
  )

  create_rows(
    "#{WITHOUT_PKEY}",
    loops,
    procs
  )

  save_table(WITH_PKEY)
  save_table(WITHOUT_PKEY)
end

TITLE_LENGTH = 70

puts '# 主キーなしテーブルスキーマ' + CREATE_TABLE_WITH_PKEY
puts ''
puts '# 主キーありテーブルスキーマ' + CREATE_TABLE_WITHOUT_PKEY

research do
  create_data
  Benchmark.bm(TITLE_LENGTH) do |x|
    query = "DELETE FROM #{WITH_PKEY}"
    x.report(query) do
      # 本当はstreaming使うべきだが
      query(query)
    end
    query = "DELETE FROM #{WITHOUT_PKEY}"
    x.report(query) do
      # 本当はstreaming使うべきだが
      query(query)
    end
  end

  create_data
  Benchmark.bm(TITLE_LENGTH) do |x|
    query = "DELETE FROM #{WITH_PKEY} WHERE created_at < current_date()"
    x.report(query) do
      query(query)
    end
    query = "DELETE FROM #{WITHOUT_PKEY} WHERE created_at < current_date()"
    x.report(query) do
      query(query)
    end
  end

  create_data
  Benchmark.bm(TITLE_LENGTH) do |x|
    query = "DELETE FROM #{WITH_PKEY} WHERE id < #{CHANGE_POINT}"
    x.report(query) do
      query(query)
    end
    query = "DELETE FROM #{WITHOUT_PKEY} WHERE created_at < current_date()"
    x.report(query) do
      query(query)
    end
  end
end

__END__

# 考察

idいらないな、、、
削除対象データが増えれば増えるほどid指定のほうが早く消せそうだけど、
実際idで決めきるのは危ういし（fluentdの受けたデータのcreated_atがテーブルの
created_atになるし）




# 以下ベンチマークデータ

# 主キーなしテーブルスキーマ
CREATE TABLE delete_with_pkey (
  `id`          bigint(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `json`        text NOT NULL,
  `created_at`  datetime ,
  PRIMARY KEY  (`id`),
  INDEX `idx01` (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

# 主キーありテーブルスキーマ
CREATE TABLE delete_without_pkey (
  `json`        text NOT NULL,
  `created_at`  datetime ,
  INDEX `idx01` (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

# 40万件中20万件が削除対象の場合
                                                                             user     system      total        real
DELETE FROM delete_with_pkey                                             0.000000   0.000000   0.000000 ( 26.199604)
DELETE FROM delete_without_pkey                                          0.000000   0.000000   0.000000 ( 30.180462)
                                                                             user     system      total        real
DELETE FROM delete_with_pkey WHERE created_at < current_date()           0.000000   0.000000   0.000000 ( 13.148196)
DELETE FROM delete_without_pkey WHERE created_at < current_date()        0.000000   0.000000   0.000000 ( 15.285352)
                                                                             user     system      total        real
DELETE FROM delete_with_pkey WHERE id < 200000                           0.000000   0.000000   0.000000 ( 13.283233)
DELETE FROM delete_without_pkey WHERE created_at < current_date()        0.000000   0.000000   0.000000 ( 15.556888)

# 40万件中2万件が削除対象の場合

DELETE FROM delete_with_pkey                                             0.000000   0.000000   0.000000 ( 25.730908)
DELETE FROM delete_without_pkey                                          0.000000   0.000000   0.000000 ( 29.957081)
                                                                             user     system      total        real
DELETE FROM delete_with_pkey WHERE created_at < current_date()           0.000000   0.000000   0.000000 (  0.224491)
DELETE FROM delete_without_pkey WHERE created_at < current_date()        0.000000   0.000000   0.000000 (  0.228848)
                                                                             user     system      total        real
DELETE FROM delete_with_pkey WHERE id < 20000                            0.000000   0.000000   0.000000 (  1.312694)
DELETE FROM delete_without_pkey WHERE created_at < current_date()        0.000000   0.010000   0.010000 (  0.200570)
