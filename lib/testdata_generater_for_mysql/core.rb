# -*- coding: utf-8 -*-

require 'progressbar'
require 'mysql2wrapper'
require 'logger'

#
# TODO 以下の削除 サンプルの作成
#
# 使い方
#
# ・まずは本ファイルをrequiresします
#
# ・setup_mysql_settingsでmysql2のclientを内部的に作成（@__clientで作成します）
# ・あとはcreate_rowsメソッドを使ってください
# ・基本的にインサート文のすべてのvalueにシングルクォーテーションで囲まれます。が、列名が「***_at」の場合は除く（もし特定の日時を入れたい場合は Proc.new{"'2001-10-14'"}のようにシングルクォーテーションを含めて設定してください
# ・insert__per_rowsにてマルチプルインサートの単位が設定できます（デフォルトは100）
#
#  #
#  # テーブル名
#  # ループ達（配列で）
#  # 各列の値の作成方法
#  #
#  create_rows(
#    'm_pkey_or_index__index',
#    [
#      [:brand_id,(1..13)],
#      [:user_id,(1..100)]
#    ],
#    :brand_id=>Proc.new{|v|v[:brand_id]},
#    :user_id=>Proc.new{|v|v[:user_id]},
#    :name=>Proc.new{|v|"#{v[:brand_id]}_#{v[:user_id]}_name"},
#    :value1=>Proc.new{rand(10000)},
#    :created_at=>Proc.new{'NOW()'},
#  )
#

module TestdataGeneraterForMysql

  INSERT_PER_ROWS = 100

  def setup_mysql_client(hash)
    @__client = Mysql2wrapper::Client.new(hash,nil)
    #@__client = Mysql2wrapper::Client.new(hash)
  end

  def insert_per_rows(v)
    @__insert_per_rows = v
  end

  def get_insert_per_rows
    @__insert_per_rows ||= INSERT_PER_ROWS
  end

  def hide_progress_bar
    @__disable_progress_bar = true
  end

  def random_loop
    @__random_loop = true
  end

  def query(q)
    @__client.query(q)
  end

  def create_rows(table_name,loops,col_procs)
    if loops.size == 0
      raise 'loops size must be bigger than 0'
    end

    total_rows = 0
    loops.each_with_index do |l,i|
      if i == 0
        total_rows = l[1].count
      else
        total_rows *= l[1].count
      end
    end
    @__table_name = table_name
    raise 'something wrong' if @__insert_values && @__insert_values.size > 0
    @__insert_values = []
    @__inserted_rows = 0
    @__col_procs = col_procs
    unless @__disable_progress_bar
      title = "create rows for #{table_name}"
      width = 60
      $stderr.puts title.center(title.size + 6,' ').center(width,'=')
      @__pbar = ProgressBar.new('', total_rows, $stderr)
      @__pbar.format_arguments = [:percentage, :bar, :stat]
      @__pbar.format = "%3d%% %s %s"
    end

    if @__random_loop
      random_looping(loops,0)
    else
      looping(loops,0)
    end
    do_insert # あまりの作成

    if @__pbar
      @__pbar.finish
    end
  end

  def random_looping(loop_array,index,values={},array=[])
    loop_array[index][1].each do |i|
      values[loop_array[index][0]] = i
      next_index = index + 1
      if loop_array.size > next_index
        random_looping(loop_array,next_index,values,array)
      elsif loop_array.size == next_index
        array << values.clone
      end
    end

    if index == 0
      array.shuffle.each do |values|
        hash = {}
        @__col_procs.each do |key,proc|
          hash[key] = proc.call(values)
        end
        set_insert_values(hash)
      end
    end
  end

  def looping(loop_array,index,values={})
    loop_array[index][1].each do |i|
      values[loop_array[index][0]] = i
      next_index = index + 1
      if loop_array.size > next_index
        looping(loop_array,next_index,values)
      elsif loop_array.size == next_index
        hash = {}
        @__col_procs.each do |key,proc|
          hash[key] = proc.call(values)
        end
        set_insert_values(hash)
      end
    end
  end

  def set_insert_values(hash)
    @__insert_values ||= []
    @__insert_values << hash
    if @__insert_values.size > get_insert_per_rows
      do_insert
    end
  end

  def do_insert
    return if @__insert_values.size == 0
    @__client.insert(@__client.escape(@__table_name),@__insert_values)
    @__pbar.inc(@__insert_values.size) if @__pbar
    @__insert_values = []
  end

  def generate
    only_test = ARGV.size == 1 && %w|test only_test t|.include?(ARGV[0])
    if only_test
      puts 'skip generate test datas!'
    else
      yield
    end
  end

  def research
    yield
  end
end



