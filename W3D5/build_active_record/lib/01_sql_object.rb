require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    return @columns if @columns 
    cols = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL
      cols_first = cols.first.map!(&:to_sym)
      @columns = cols_first  

  end



  def self.finalize!
    self.columns.each do |name|
      define_method(name) do 
        self.attributes[name]
      end 

      define_method("#{name}=") do |arg| 
        self.attributes[name] = arg 
    end 
  end
end 

  def self.table_name=(table_name)
    @table_name = table_name 
  end

  def self.table_name
    @table_name || self.name.tableize 
  end

  def self.all
    all = DBConnection.execute(<<-SQL)
    SELECT 
      *
    FROM 
      #{self.table_name}
    SQL
    parse_all(all) 
  end

  def self.parse_all(all)
    all.map { |result| self.new(result) }
  end

  def self.find(id)
    items = DBConnection.execute(<<-SQL,id)

    SELECT 
      *
    FROM 
      #{table_name}
    WHERE
       id = ? 
    SQL

    parse_all(items).first 
  end

  def initialize(params = {})
    #iterate through attr value pairs 
    params.each do |attr_name, value| 
    #convert name to symbol 
      attr_name = attr_name.to_sym 
    #check if name is among columns 
        if self.class.columns.include?(attr_name) 
          self.send("#{attr_name}=", value)
        else ""
          raise "unknown attribute '#{attr_name}'"
        end 
      end 
  end

  def attributes
    @attributes ||= {} 
  end

  def attribute_values
    self.attributes.values 
  end

  def insert
    # drop 1 to avoid inserting id (the first column)
    columns = self.class.columns.drop(1)
    col_names = columns.map(&:to_s).join(", ")
    question_marks = (["?"] * columns.count).join(", ")

    DBConnection.execute(<<-SQL, *attribute_values.drop(1))
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
    SQL

    self.id = DBConnection.last_insert_row_id

  end

  def update
    # ...
  end

  def save
    if id.nil? 
      self.insert
    else 
      self.update 
    end 
  end
end
