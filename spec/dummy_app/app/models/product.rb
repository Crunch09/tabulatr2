if USE_MONGOID
  class Product
    include Mongoid::Document

    has_and_belongs_to_many :tags
    belongs_to :vendor
    field :name,        :type => String
    field :url,         :type => String
    field :active,      :type => Boolean
    field :description, :type => String
    field :price,       :type => Fixnum
  end
else
  class Product < ActiveRecord::Base

    has_and_belongs_to_many :tags
    belongs_to :vendor

  end
end