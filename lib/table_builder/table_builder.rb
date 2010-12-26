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

  PAGINATE_NAME = :pagination
  FILTER_NAME   = :filter
  SORT_NAME     = :sort_by

  # these settings are considered constant for the whole application, can not be overridden
  # on a per-table basis
  TABLE_DESIGN_OPTIONS = {
    :sortable => 'sortable',                    # class for the header of a sortable column
    :sorting_asc => 'sort-asc',                 # class for the currently asc sorting column
    :sorting_desc => 'sorting-desc',            # class for the currently desc sorting column
    :page_left_id => 'page-left',               # id for the page left <a>
    :page_right_id => 'page-right',             # id for the page right <a>
    :page_no_id => 'page-no',                   # id for the page no <input>
    :control_div_id => 'table-controls',        # id of the div containing the paging and batch action controls
    :paginator_div_id => 'paginator',           # id of the div containing the paging controls
    :batch_actions_div_id => 'batch-actions',   # id of the dic containing the batch action controls
    :batch_action_name => 'batch_action',       # name of the batch action param
    :sort_by_key => 'sort_by_key',              # name of key which to search, format is 'id asc'
    :paginate_name => 'pagination',             # name of the param w/ the pagination infos
    :per_page => 20                             # default page length
    #...
  }
  
  PAGINATE_OPTIONS = {
    :per_page => 10,
    :page => 1
    # more...
  }

  # Hash keeping the defaults for the table options, may be overriden in the
  # table_for call
  TABLE_OPTIONS = {
    :table_html => false,        # a hash with html attributes for the table
    :row_html => false,          # a hash with html attributes for the normal trs
    :header_html => false,       # a hash with html attributes for the header trs
    :filter_html => false,       # a hash with html attributes for the filter trs
    :filter => true,             # false for no filter row at all
    :paginate => false,          # true to show paginator
    :sortable => false,          # true to allow sorting (can be specified for every sortable column)
    :make_form => true,          # whether or not to wrap the whole table (incl. controls) in a form
    :action => nil,              # target action of the wrapping form if applicable
    :method => 'post',           # http method for that form if applicable
    :batch_actions => false,     # name => value hash of batch action stuff
    :join_symbol => ', '         # symbol used to join the elements of 'many' associations
    #...
  }

  # Hash keeping the defaults for the column options
  COLUMN_OPTIONS = {
    :header => false,        # a string to write into the header cell
    :width => false,         # the width of the cell
    :align => false,         # horizontal alignment
    :valign => false,        # vertical alignment
    :wrap => true,           # wraps
    :type => :string,        # :integer, :date
    :td_html => false,       # a hash with html attributes for the cells
    :th_html => false,       # a hash with html attributes for the header cell
    :filter_html => false,   # a hash with html attributes for the filter cell
    :filter_html => false,   # a hash with html attributes for the filter cell
    :filter => true,         # false for no filter field, array-of-names, hash-of-names-values for select, ClassName for foreign keys
    :filter_like => false,   # true to filter w/ like %?%
    :format => false,        # a sprintf-string or a proc to do special formatting
    :method => false,        # if you want to get the column by a different method than its name
    :sortable => false       # if set, sorting-stuff is added to the header cell
    #...
  }

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
    @view.concat(s) if @view
    puts "\# '#{s}'" 
    @val << s
  end

  # render the hidden input field that containing the current sort key
  def render_sort_field
    # FIXME take 'current' value
    make_tag(:input, :type => :hidden, :name => TABLE_DESIGN_OPTIONS[:sort_by_name], :value => '')
  end

  #render the paginator controls, inputs etc.
  def render_paginator
    make_tag(:div, :id => TABLE_DESIGN_OPTIONS[:paginator_div_id]) do
      make_tag(:a, :href => '#', :id => TABLE_DESIGN_OPTIONS[:page_left_id]) do
        concat "&lt;"
      end # </a>
      # FIXME find current page number
      make_tag(:input, :type => :hidden, :name => TABLE_DESIGN_OPTIONS[:page_nr], :value => '')
      concat("/...")
      make_tag(:a, :href => '#', :id => TABLE_DESIGN_OPTIONS[:page_right_id]) do
        concat "&gt;"
      end # </a>      
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
    v = if block_given?
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


# These are extensions for use from ActionController instances
# In a seperate class call only for clearity
class TableBuilder

  def self.get_table_options(params, opts={})
    val = {}
    val[:paginate] = PAGINATE_OPTIONS.merge(opts).merge(params[PAGINATE_NAME] || {})
    val[:filter] = params[FILTER_NAME].inject(["(1=1) ", []]) do |c, t|
      n, v = t
      # FIXME n = name_escaping(n)
      raise "SECURITY violation, field name is '#{n}'" unless /^[\d\w]+$/.match n 
      if (params["#{FILTER_NAME}_matcher".to_sym] || {})[n]=='like'
        m = 'like'
        v = "%#{v}%"
      else m = '=' end
      [c[0] << "AND (`#{n}` #{m} ?) ", c[1] << v]
    end
    # FIXME escaping!!!
    val[:sort_by] = '...'
    val
  end
end


# These are extensions for use as a row builder
# In a seperate class call only for clearity
class TableBuilder

  # called inside the build_table block, branches into data, header,
  # or filter building methods depending on the current mode
  def column(name, opts={}, &block)
    case @row_mode
    when :data   then data_column(name, opts, &block)
    when :header then header_column(name, opts, &block)
    when :filter then filter_column(name, opts, &block)
    else raise "Wrong row mode '#{@row_mode}'"
    end # case
  end

  # called inside the build_table block, branches into data, header,
  # or filter building methods depending on the current mode
  def association(relation, name, opts={}, &block)
    case @row_mode
    when :data   then data_association(relation, name, opts, &block)
    when :header then header_association(relation, name, opts, &block)
    when :filter then filter_association(relation, name, opts, &block)
    else raise "Wrong row mode '#{@row_mode}'"
    end # case
  end

private
  # returns self, sets record and row_mode as required for a
  # data row
  def data_row_builder(record)
    @record = record
    @row_mode = :data
    self
  end

  # returns self, sets record to nil and row_mode as required for a
  # header row
  def header_row_builder
    @record = nil
    @row_mode = :header
    self
  end

  # returns self, sets record to nil and row_mode as required for a
  # filter row
  def filter_row_builder
    @record = nil
    @row_mode = :filter
    self
  end

  # some preprocessing of the options
  def normalize_column_options(opts)
    opts = COLUMN_OPTIONS.merge(opts)
    {:width => 'width', :align => 'text-align', :valign => 'vertical-align'}.each do |key,css|
      if opts[key]
        [:th_html, :filter_html, :td_html].each do |set|
          opts[set] ||= {}
          opts[set][:style] = (opts[set][:style] ? opts[set][:style] << "; " : "") << "#{css}: #{opts[key]}"
        end # each
      end # if
    end # each
    # more to come!
    opts
  end
end

Dir[File.dirname(__FILE__) + "/table_builder/*.rb"].each do |file| 
  require file
end
