module Forem
  class ForumSerializer < ActiveModel::Serializer
    attributes :id, :name, :description, :category_id, :views_count
  end
end
