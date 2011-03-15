require 'spec_helper'

describe "Tabulatrs" do

  names = ["lorem", "ipsum", "dolor", "sit", "amet", "consectetur",
  "adipisicing", "elit", "sed", "eiusmod", "tempor", "incididunt", "labore",
  "dolore", "magna", "aliqua", "enim", "minim", "veniam,", "quis", "nostrud",
  "exercitation", "ullamco", "laboris", "nisi", "aliquip", "commodo",
  "consequat", "duis", "aute", "irure", "reprehenderit", "voluptate", "velit",
  "esse", "cillum", "fugiat", "nulla", "pariatur", "excepteur", "sint",
  "occaecat", "cupidatat", "non", "proident", "sunt", "culpa", "qui",
  "officia", "deserunt", "mollit", "anim", "est", "laborum"]

  vendor1 = Vendor.create!(:name => "ven d'or", :active => true)
  vendor2 = Vendor.create!(:name => 'producer', :active => true)
  tag1 = Tag.create!(:title => 'foo')
  tag2 = Tag.create!(:title => 'bar')
  tag3 = Tag.create!(:title => 'fubar')
  name

  describe "GET /index_simple" do
    it "works in general" do
      get index_simple_products_path
      response.status.should be(200)
    end

    it "contains buttons" do
      visit index_simple_products_path
      [:submit_label, :select_all_label, :select_none_label, :select_visible_label,
        :unselect_visible_label, :select_filtered_label, :unselect_filtered_label
      ].each do |n|
        page.should have_button(Tabulatr::TABLE_OPTIONS[n])
      end
    end

    it "contains column headers" do
      visit index_simple_products_path
      ['Id','Title','Price','Active','Vendor Name','Tags Title'].each do |n|
        page.should have_content(n)
      end
    end

    it "contains other elements" do
      visit index_simple_products_path
      page.should have_content(sprintf(Tabulatr::TABLE_OPTIONS[:info_text], 0, 0, 0, 0))
    end

    it "contains the actual data" do
      product = Product.create!(:title => names[0], :active => true, :price => 10.0, :description => 'blah blah', :vendor => vendor1)
      visit index_simple_products_path
      page.should have_content(names[0])
      page.should have_content("true")
      page.should have_content("10.0")
      page.should have_content("ven d'or")
      page.should have_content(sprintf(Tabulatr::TABLE_OPTIONS[:info_text], 1, 1, 0, 1))
    end

    it "contains the actual data multiple" do
      9.times do |i|
        product = Product.create!(:title => names[i+1], :active => i.even?, :price => 11.0+i, 
          :description => "blah blah #{i}", :vendor => i.even? ? vendor1 : vendor2)
        visit index_simple_products_path
        page.should have_content(names[i])
        page.should have_content((11.0+i).to_s)
        page.should have_content(sprintf(Tabulatr::TABLE_OPTIONS[:info_text], i+2, i+2, 0, i+2))
      end
    end

    it "contains the further data on the further pages" do
      names[10..-1].each_with_index do |n,i|
        product = Product.create!(:title => n, :active => i.even?, :price => 30.0+i, 
          :description => "blah blah #{i}", :vendor => i.even? ? vendor1 : vendor2)
        visit index_simple_products_path
        page.should_not have_content(n)
        page.should_not have_content((30.0+i).to_s)
        page.should have_content(sprintf(Tabulatr::TABLE_OPTIONS[:info_text], 10, i+11, 0, i+11))
      end
    end

    it "pages up and down" do
      visit index_simple_products_path
      k = 1+names.length/10
      k.times do |i|
        ((i*10)...[names.length, ((i+1)*10)].min).each do |j|
          page.should have_content(names[j])
        end
        if i==0
          page.should have_no_button('product_pagination_page_left')
        else
          page.should have_button('product_pagination_page_left')
        end
        if i==k-1
          page.should have_no_button('product_pagination_page_right')
        else
          page.should have_button('product_pagination_page_right')
          click_button('product_pagination_page_right')
        end
      end
      # ...and down
      k.times do |ii|
        i = k-ii-1
        ((i*10)...[names.length, ((i+1)*10)].min).each do |j|
          page.should have_content(names[j])
        end
        if i==k-1
          page.should have_no_button('product_pagination_page_right')
        else
          page.should have_button('product_pagination_page_right')
        end
        if i==0
          page.should have_no_button('product_pagination_page_left')
        else
          page.should have_button('product_pagination_page_left')
          click_button('product_pagination_page_left')
        end
      end

    end

    it "jumps to the correct page" do
      visit index_simple_products_path
      k = 1+names.length/10
      l = (1..k).entries.shuffle
      l.each do |ii|
        i = ii-1
        fill_in("product_pagination[page]", :with => ii.to_s)
        click_button("Apply")
        ((i*10)...[names.length, ((i+1)*10)].min).each do |j|
          page.should have_content(names[j])
        end
        if i==0
          page.should have_no_button('product_pagination_page_left')
        else
          page.should have_button('product_pagination_page_left')
        end
        if i==k-1
          page.should have_no_button('product_pagination_page_right')
        else
          page.should have_button('product_pagination_page_right')
        end
      end
    end

    it "filters" do
      visit index_simple_products_path
      #save_and_open_page
      fill_in("product_filter[title]", :with => "lorem")
      click_button("Apply")
      page.should have_content("lorem")
      page.should have_content(sprintf(Tabulatr::TABLE_OPTIONS[:info_text], 1, names.length, 0, 1))
      fill_in("product_filter[title]", :with => "loreem")
      click_button("Apply")
      page.should_not have_content("lorem")
      page.should have_content(sprintf(Tabulatr::TABLE_OPTIONS[:info_text], 0, names.length, 0, 0))
    end

    it "filters with like" do
      visit index_filters_products_path
      %w{a o lo lorem}.each do |str|
        fill_in("product_filter[title][like]", :with => str)
        click_button("Apply")
        save_and_open_page
        page.should have_content(str)
        tot = (names.select do |s| s.match Regexp.new(str) end).length
        page.should have_content(sprintf(Tabulatr::TABLE_OPTIONS[:info_text], [10,tot].min, names.length, 0, tot))
      end
    end



  end

  describe "GET /products empty" do
    it "works in general" do
      get products_path
      response.status.should be(200)
    end
  end


end





