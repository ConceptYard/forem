module Forem
  class ForumSerializer < ActiveModel::Serializer
    attributes :id, :name, :slug, :description, :category_id, :views_count
  end
end
