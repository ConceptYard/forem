module Forem
  class ForumSerializer < ActiveModel::Serializer
    attributes :id, :name, :slug, :description, :category_id, :views_count, :discussions_count

    def discussions_count
      object.posts.count
    end
  end
end
