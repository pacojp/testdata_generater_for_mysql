# -*- coding: utf-8 -*-

require 'rubygems'
require 'testdata_generater_for_mysql'
require 'benchmark'

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

TABLE = "extract_by_int_or_varchar_tests"

# 20種のタイプがあり各々10万レコード保持
CNT_PARENT = 20
CNT_CHILD  = 100_000

def varchar_col_value(i)
  i.to_s.rjust(10,'0')
end

generate do
  query "DROP TABLE IF EXISTS #{TABLE};"
  query "
CREATE TABLE #{TABLE} (
  `id`          int(11) NOT NULL auto_increment,
  `int_col`     int(11) NOT NULL,
  `varchar_col` varchar(20),
  `some_value`  int(11) NOT NULL,
  `created_at`  datetime ,
  PRIMARY KEY  (`id`),
  KEY `idx_int_col` USING BTREE (`int_col`),
  KEY `idx_varchar_col` USING BTREE (`varchar_col`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
"

  loops = [
    [:parent, (1..CNT_PARENT)],
    [:child, (1..CNT_CHILD)],
  ]

  procs = {
    :int_col     => proc{|v|v[:parent]},
    :varchar_col => proc{|v|varchar_col_value(v[:parent])},
    :some_value  => proc{rand(10000)}, # Time,DateTime,Date
    :created_at  => proc{'NOW()'.to_func},
  }

  create_rows(
    TABLE,
    loops,
    procs
  )
end

test do
  samples = [1,11,19,8,2,16]
  Benchmark.bmbm do |x|
    x.report("int_col") do
      samples.each do |i|
        query = "SELECT COUNT(id) FROM #{TABLE} WHERE int_col = #{i}"
        query(query)
      end
    end
    x.report("varchar_col") do
      samples.each do |i|
        query = "SELECT COUNT(id) FROM #{TABLE} WHERE varchar_col = '#{varchar_col_value(i)}'"
        query(query)
      end
    end
  end
end

__END__

結果としては2倍程度のパフォーマンス差が出ました。
結構悩ましい差かなと、、、、

===   create rows for extract_by_int_or_varchar_tests   ====
100% |ooooooooooooooooooooooooooooooooooooooooooooo| Time:   0:01:32
Rehearsal -----------------------------------------------
int_col       0.000000   0.000000   0.000000 (  0.164813)
varchar_col   0.000000   0.000000   0.000000 (  0.342319)
-------------------------------------- total: 0.000000sec

                  user     system      total        real
int_col       0.000000   0.000000   0.000000 (  0.153482)
varchar_col   0.000000   0.000000   0.000000 (  0.321076)
