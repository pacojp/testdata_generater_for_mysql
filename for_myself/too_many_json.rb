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

TABLE = "too_many_jsons"

# 100万レコード保持
CNT_PARENT = 1_000_000

def varchar_col_value(i)
  i.to_s.rjust(10,'0')
end

generate do
  query "DROP TABLE IF EXISTS #{TABLE};"
  query "
CREATE TABLE #{TABLE} (
  `id`          int(11) NOT NULL auto_increment,
  `json`        text NOT NULL,
  `created_at`  datetime ,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
"
  # ループランダムで回す(メモリを食います(100万レコードで500M〜))
  random_loop
  loops = [
    [:parent, (1..CNT_PARENT)],
  ]

  st1 = 'a' * 60
  st2 = 'b' * 60
  st3 = 'あ' * 60

  procs = {
    :json       => proc{
        hash = {}
        (1..20).each do |i|
          hash[i] = rand(100)
        end
        hash['st1'] = st1
        hash['st2'] = st2
        hash['st3'] = st3

        hash.to_json
      },
    :created_at => proc{'NOW()'.to_func},
  }

  create_rows(
    TABLE,
    loops,
    procs
  )
end

research do
  Benchmark.bmbm do |x|
    x.report("parse_json_cost") do
      query = "SELECT * FROM #{TABLE}"
      # 本当はstreaming使うべきだが
      query(query).each do |row|
        JSON.parse(row['json'])
      end
    end
  end
end

__END__

# ベンチを取ろうとした理由

とある案件でfluentdを使ったアプリのアクセスログの解析を行いたいとなった。
が、mongoDBを設置運用するためのコストは払ってもらえない。
じゃぁmysqlはどうよ？と。同プロジェクトでmysqlは使用するし、
mysqlの運用であれば慣れたものなのでコストの問題も気にしなくていいよね、、、
でもスキーマレスな感じにはしておきたいよね、、、。
mysqlを無理くり使うとどんな感じになるかね？ってな流れ。

# 実行環境

macbook pro 15 retina

# ベンチからの考察

intが100、60文字の文字列が3つ入ったjsonを100万行パース。
で、3分程度なので、(ちなみにintが100のjsonが相手だと17秒程度だった)
まぁそれなりのアクセス数なサイトであればfluentdのデータストレージに
mysqlを使うのもありかと思います。


# 実行結果

```

============   create rows for too_many_jsons   ============
100% |oooooooooooooooooooooooooooooooooooooooooooooooooooooooo| Time:   0:02:16
Rehearsal ---------------------------------------------------
parse_json_cost 179.620000   2.300000 181.920000 (184.986380)
---------------------------------------- total: 181.920000sec

                      user     system      total        real
parse_json_cost 178.210000   1.400000 179.610000 (183.522008)

```
