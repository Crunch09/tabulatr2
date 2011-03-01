#--
# Copyright (c) 2010-2011 Peter Horn, Provideal GmbH
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

# These are extensions for use from ActionController instances
module Tabulatr::Finder

  require File.join(File.dirname(__FILE__), 'finder', 'find_for_active_record_table')
  require File.join(File.dirname(__FILE__), 'finder', 'find_for_mongoid_table')

  # compress the list of ids as good as I could imagine ;)
  # uses fancy base twisting
  def self.compress_id_list(list)
    return "PXS" if list.length == 0
    "PXS" << (list.sort.uniq.map(&:to_i).inject([[-9,-9]]) do |l, c|
      if l.last.last+1 == c
        l.last[-1] = c
        l
      else
        l << [c,c]
      end
    end.map do |r|
      if r.first == r.last
        r.first.to_s(8)
      else
        r.first.to_s(8) << "8" << r.last.to_s(8)
      end
    end[1..-1].join("9").to_i.to_s(36))
  end

  # inverse of compress_id_list
  def self.uncompress_id_list(str)
    return [] if !str.present? or str=='0' or str=='PXS'
    raise "Corrupted id list. Or a bug ;)" unless str.start_with?("PXS")
    n = str[3..-1].to_i(36).to_s.split("9").map do |e|
      p = e.split("8")
      if p.length == 1 then p[0].to_i(8)
      elsif p.length == 2 then (p[0].to_i(8)..p[1].to_i(8)).entries
      else raise "Corrupted id list. Or a bug ;)"
      end
    end.flatten.map &:to_s
  end

  class Invoker
    def initialize(batch_action, ids)
      @batch_action = batch_action.to_sym
      @ids = ids
    end

    def method_missing(name, *args, &block)
      if @batch_action == name
        yield(@ids, args)
      end
    end
  end

private

  def self.class_to_param(klaz)
    klaz.to_s.downcase.gsub("/","_")
  end

  def self.condition_from(n,v,c)
    raise "SECURITY violation, field name is '#{n}'" unless /^[\d\w]+(\.[\d\w]+)?$/.match n
    @like ||= Tabulatr.sql_options[:like]
    nc = c
    if v.is_a?(String)
      if v.present?
        nc = [c[0] << "AND (#{n} = ?) ", c[1] << v]
      end
    elsif v.is_a?(Hash)
      if v[:like]
        if v[:like].present?
          nc = [c[0] << "AND (#{n} #{@like} ?) ", c[1] << "%#{v[:like]}%"]
        end
      else
        nc = [c[0] << "AND (#{n} > ?) ", c[1] << "#{v[:from]}"] if v[:from].present?
        nc = [nc[0] << "AND (#{n} < ?) ", nc[1] << "#{v[:to]}"] if v[:to].present?
      end
    else
      raise "Wrong filter type: #{v.class}"
    end
    nc
  end
end
