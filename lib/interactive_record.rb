require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord

  def self.table_name
    self.to_s.downcase.pluralize
  end

  def self.column_names
    DB[:conn].results_as_hash = true

    sql = <<-SQL
    PRAGMA table_info('#{table_name}')
    SQL

    column_names = DB[:conn].execute(sql).map { |row| row["name"] }.compact
  end

  def initialize(options={})
    options.each { |property, value| self.send("#{property}=", value) }
  end

  def save
    sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  def table_name_for_insert
    self.class.table_name
  end

  def values_for_insert
    values =  self.class.column_names.map do |col_name|
      "'#{send(col_name)}'" unless send(col_name).nil?
    end.drop(1).join(", ")
  end

  def col_names_for_insert
    self.class.column_names.delete_if {|col| col == "id"}.join(", ")
  end

  def self.find_by_name(name)
    sql = "SELECT * FROM #{self.table_name} WHERE name = '#{name}'"
    DB[:conn].execute(sql)
  end

  def self.find_by(attrib)
    sql = "SELECT * FROM #{self.table_name} WHERE ? = '#{attrib}'"
    DB[:conn].execute(sql, attrib.to_s)
  end

end
