# TableBuilder is a class to allow easy creation of data tables as you
# frequently find them on 'index' pages in rails. The 'table convention'
# here is that we consider every table to consist of three parts:
# * a header containing the names of the attribute of the column
# * a filter which is an input element to allow for searching the
#   particular attribute
# * the rows with the actual data.
#
# Author::    Peter Horn, (mailto:peter.horn@provideal.net)
# Copyright:: Copyright (c) 2010 by Provideal Systems GmbH (http://www.provideal.net)
# License::   MIT, APACHE, Ruby, whatever, something free, ya know?
class TableBuilder

  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::FormTagHelper
  include ActionView::Helpers::FormOptionsHelper

  # Constructor of TableBuilder
  #
  # Parameters:
  # <tt>records</tt>:: the 'row' data of the table
  # <tt>view</tt>:: the current instance of ActionView
  # <tt>opts</tt>:: a hash of options specific for this table
  def initialize(records, view=nil, table_options={})
    @records = records
    @view = view
    @table_options = TABLE_OPTIONS.merge(table_options)
    @val = []
    @record = nil
    @row_mode = false
  end

  # the actual table definition method. It takes an Array of records, a hash of
  # options and a block with the actual <tt>column</tt> calls.
  #
  # The following options are evaluated here:
  # <tt>:table_html</tt>:: a hash with html-attributes added to the <table> created
  # <tt>:header_html</tt>:: a hash with html-attributes added to the <tr> created
  #                         for the header row
  # <tt>:filter_html</tt>:: a hash with html-attributes added to the <tr> created
  #                         for the filter row
  # <tt>:row_html</tt>:: a hash with html-attributes added to the <tr>s created
  #                      for the data rows
  # <tt>:filter</tt>:: if set to false, no filter row is output
  def build_table(&block)
    @val = []
    make_tag(@table_options[:make_form] ? :form : nil, :method => :get) do
      make_tag(:div,  :id=> TABLE_OPTIONS[:action_div_id]) do
        # FIXME: table options and stuff
        render_sort_field if @table_options[:sortable]
        render_paginator if @table_options[:paginate]
        render_batch_actions if @table_options[:batch_actions]
      end # </div>'

      make_tag(:table, @table_options[:table_html]) do
        make_tag(:thead) do
          render_table_header(&block)
          render_table_filters(&block) if @table_options[:filter]
        end # </thead>
        make_tag(:tbody) do
          render_table_rows(&block)
        end # </tbody>
      end # </table>
    end # </form>
    @val.join("\n")
  end

private
  # either append to the internal string buffer or use
  # ActionView#concat to output if an instance is available.
  def concat(s)
    @view.concat(s) if (Rails.version.to_f < 3.0 && @view)
    #puts "\##{Rails.version.to_f} '#{s}'"
    @val << s
  end

  # render the hidden input field that containing the current sort key
  def render_sort_field
    # FIXME take 'current' value
    make_tag(:input, :type => :hidden, :name => TABLE_DESIGN_OPTIONS[:sort_by_name], :value => '')
  end

  #render the paginator controls, inputs etc.
  def render_paginator
    # get the current pagination state
    pparams = PAGINATE_OPTIONS.merge(@view.params[TABLE_FORM_OPTIONS[:pagination]] || {})
    page = pparams[:page].to_i
    pagesize = pparams[:pagesize].to_i
    pagesizes = pparams[:pagesizes].map &:to_i
    # render the 'wrapping' div
    make_tag(:div, :id => TABLE_DESIGN_OPTIONS[:paginator_div_id]) do
      # < 
      make_tag(:a, :href => '#', :id => TABLE_DESIGN_OPTIONS[:page_left_id]) do
        concat "&lt;"
      end if page > 0 # </a>
      # current page number
      concat(make_tag(:input, 
        :type => :hidden, 
        :name => "#{TABLE_FORM_OPTIONS[:pagination_name]}[current_page]", 
        :value => page))
      concat(make_tag(:input, 
        :type => :text,
        :size => 3,
        :name => "#{TABLE_FORM_OPTIONS[:pagination_name]}[page]", 
        :value => page))
      concat("/...")
      make_tag(:a, :href => '#', :id => TABLE_DESIGN_OPTIONS[:page_right_id]) do
        concat "&gt;"
      end if true # </a>
      make_tag(:select, :name => TABLE_FORM_OPTIONS[:pagination_name][:pagesize], :id => TABLE_DESIGN_OPTIONS[:batch_actions_name]) do
        @table_options[:batch_actions].each do |n,v|
          make_tag(:option, :value => n) do
            concat(v)
          end # </option>
        end # each
      end # </select>
      # FIXME attach js actions to pager controls
    end # </div>
  end

  # render the select tag for batch actions
  def render_batch_actions
    make_tag(:div, :id => TABLE_OPTIONS[:batch_actions_div_id]) do
      make_tag(:select, :name => TABLE_OPTIONS[:batch_actions_name], :id => TABLE_OPTIONS[:batch_actions_name]) do
        @table_options[:batch_actions].each do |n,v|
          make_tag(:option, :value => n) do
            concat(v)
          end # </option>
        end # each
      end # </select>
      # FIXME add js trigger stuff if appropriate
    end # </div>
  end

  # render the header row
  def render_table_header(&block)
    make_tag(:tr, @table_options[:header_html]) do
      yield(header_row_builder)
    end # </tr>"
  end

  # render the filter row
  def render_table_filters(&block)
    make_tag(:tr, @table_options[:filter_html]) do
      yield(filter_row_builder)
    end # </tr>
  end

  # render the table rows
  def render_table_rows(&block)
    @records.each_with_index do |record, i|
      concat("<!-- Row #{i} -->")
      make_tag(:tr, @table_options[:row_html]) do
        yield(data_row_builder(record))
      end # </tr>
    end
  end

  # stringly produce a tag w/ some options
  def make_tag(name, hash={}, &block)
    attrs = hash ? tag_options(hash) : ''
    if block_given?
      if name
        concat("<#{name}#{attrs}>")
        yield
        concat("</#{name}>")
      else
        yield
      end
    else
      concat("<#{name}#{attrs} />")
    end
    nil
  end
end

Dir[File.dirname(__FILE__) + "/table_builder/*.rb"].each do |file|
  puts file
  require file
end
