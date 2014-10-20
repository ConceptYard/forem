module Forem
  class PostSerializer < ActiveModel::Serializer
    attributes :id, :topic_id, :topic_subject, :text, :user_id, :created_at, :updated_at, :reply_to_id, :state, :notified

    def topic_subject
      return object.topic.subject if object.topic.present?
      return 'Unknown'
    end
  end
end
