require 'csv'
require 'active_record'
require 'cxbrank/site_settings'

module CxbRank
  module Master
    class Base < ActiveRecord::Base
      include Comparable
      self.abstract_class = true

      def self.last_modified
        return self.maximum(:updated_at)
      end

      def self.restore_from_csv(csv)
        columns = self.get_csv_columns

        csv.read.each do |row|
          conditions = {}
          columns.each do |column|
            if column[:unique]
              if column[:foreign].present?
                key = column[:foreign].name.foreign_key.to_sym
                conditions[key] = column[:foreign].find_id(row.field(column[:name]))
              elsif column[:name] == :lookup_key
                conditions[column[:name]] = row.field(column[:name]) || row.field(:text_id)
              else
                conditions[column[:name]] = row.field(column[:name])
              end
            end
          end
          data = self.find_by(conditions)
          unless data
            data = self.new
            conditions.each do |key, value|
              data.send("#{key}=", value)
            end
          end
          columns.each do |column|
            next if column[:unique]
            if column[:foreign].present?
              key = column[:foreign].name.foreign_key
              data.send("#{key}=", column[:foreign].find_by(:text_id => row.field(column[:name])).id)
            else
              data.send("#{column[:name]}=", row.field(column[:name]))
            end
          end
          data.save!
        end
      end

      def self.dump_to_csv(csv, omit_columns=[])
        output_columns = self.get_csv_columns.keep_if do |column| column[:dump] end
        output_columns.delete_if do |column| omit_columns.include?(column[:name]) end
        column_names = output_columns.dup.collect do |column| column[:name] end

        csv << column_names
        chain = self.all
        output_columns.each do |column|
          if column[:foreign].present?
            column[:joins] = column[:foreign].table_name.singularize.to_sym
            chain = chain.joins(column[:joins])
          end
        end
        chain.each do |data|
          row = CSV::Row.new(column_names, [])
          output_columns.each do |column|
            if column[:foreign].present?
              row[column[:name]] = data.send(column[:joins]).send(:text_id)
            else
              row[column[:name]] = data.send(column[:name])
            end
          end
          csv << row
        end
      end
    end
  end
end
