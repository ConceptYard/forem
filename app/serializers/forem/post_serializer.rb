module Forem
  class PostSerializer < ActiveModel::Serializer
    attributes :id, :topic_id, :text, :user_id, :created_at, :updated_at, :reply_to_id, :state, :notified
  end
end
