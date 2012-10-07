# -*- coding: utf-8 -*-

require 'progressbar'
require 'mysql2'

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

class String
  def to_func
    @__is_function = true
    self
  end

  def function?
    if @__is_function
      true
    else
      false
    end
  end
end

module TestdataGeneraterForMysql
  def setup_mysql_client(hash)
    @__client = Mysql2::Client.new(hash)
  end

  def insert_per_rows=(v)
    @__insert_per_rows = v
  end

  def disable_progress_bar
    @__disable_progress_bar = true
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
    @__insert_per_rows ||= 100
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

    looping(loops,0)
    do_insert # あまりの作成

    if @__pbar
      @__pbar.finish
    end
  end

  def looping(ar,index,values={})
    ar[index][1].each do |i|
      values[ar[index][0]] = i
      next_index = index + 1
      if ar.size > next_index
        looping(ar,next_index,values)
      elsif ar.size == next_index
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
    if @__insert_values.size > @__insert_per_rows
      do_insert
    end
  end

  def do_insert
    return if @__insert_values.size == 0
    @__inserted_rows += @__insert_values.size
    query = <<"EOS"
INSERT INTO `#{@__client.escape(@__table_name)}`
(#{@__col_procs.keys.map{|o|"`#{@__client.escape(o.to_s)}`"}.join(',')})
VALUES
#{
  @__insert_values.map do |row|
  "(#{
    row.map do |key,value|
      case value
      when nil
        "NULL"
      when TrueClass,FalseClass
        if value
          "'1'"
        else
          "'0'"
        end
      # TODO when datetime time
      when Time,DateTime
        "'#{value.strftime("%Y-%m-%d %H:%M:%S")}'"
      when Date
        "'#{value.strftime("%Y-%m-%d")}'"
      else
        s = value
        s = s.to_s unless s.kind_of?(String)
        if s.respond_to?(:function?) && s.function?
          "#{value.to_s}"
        else
          "'#{@__client.escape(value.to_s)}'"
        end
      end
    end.join(',')
  })"
  end.join(',')
}
EOS
    @__client.query(query)
    if @__pbar
      @__pbar.inc(@__insert_values.size)
    end
    @__insert_values = []
  end
end
