module Forem
  class TopicSerializer < ActiveModel::Serializer
    attributes :id, :forum_id, :user_id, :subject, :created_at, :updated_at, :locked, :hidden, :state, :views_count, :slug
  end
end
