module Forem
  class ForumSerializer < ActiveModel::Serializer
    attributes :id, :name, :slug, :description, :category_id, :views_count, :discussions_count, :last_post_user_name #, :last_post_date

    def discussions_count
      object.posts.count
    end

    def last_post_user_name
      last_post = object.last_post_for(scope)
      if last_post.nil?
        'No Discussions'
      else
        scope.name
      end
    end

    def last_post_date
      last_post = object.last_post_for(scope)
      if last_post.nil?
        ''
      else
        "#{distance_of_time_in_words(last_post.created_at, Time.now)} ago"
      end
    end
  end
end
