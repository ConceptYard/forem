module Forem
  class TopicsController < Forem::ApplicationController
    helper 'forem/posts'
    #before_filter :authenticate_forem_user, :except => [:show]
    before_filter :restrict_access!
    before_filter :find_forum
    before_filter :block_spammers, :only => [:new, :create]

    def show
      if find_topic
        register_view(@topic, forem_user)
        @posts = find_posts(@topic)

        # Kaminari allows to configure the method and param used
        @posts = @posts.send(pagination_method, params[pagination_param]).per(10)
        respond_to do |format|
          format.html
          format.json { render json: @posts }
        end
      end
    end

    def new
      authorize! :create_topic, @forum
      @topic = @forum.topics.build
      @topic.posts.build
    end

    def create
      authorize! :create_topic, @forum
      @topic = @forum.topics.build(topic_params)
      @topic.user = forem_user || @current_user

      respond_to do |format|
        if @topic.save
          format.html { create_successful }
          format.json { render json: @topic }
        else
          format.html { create_unsuccessful }
          format.json { render json: @topic.errors }
        end
      end
    end

    def destroy
      @topic = @forum.topics.friendly.find(params[:id])
      respond_to do |format|
        if forem_user == @topic.user || forem_user.forem_admin?
          if @topic.destroy
            format.html { destroy_successful }
            format.json { render json: {message: "Topic Deleted"} }
          else
            format.html { destroy_unsuccessful }
            format.json { render json: @topic.errors }
          end
        end
      end
    end

    def subscribe
      respond_to do |format|
        if find_topic
          @topic.subscribe_user(forem_user.id)
          format.html { subscribe_successful }
          format.json { render json: {message: "Subscribed"} }
        end
      end
    end

    def unsubscribe
      respond_to do |format|
        if find_topic
          @topic.unsubscribe_user(forem_user.id)
          format.html { unsubscribe_successful }
          format.json { render json: {message: "Unsubscribed"} }
        end
      end
    end

    def post_count
      if find_topic
        count = find_posts(@topic).count
      else
        count = 0
      end
      respond_to do |format|
        format.json { render json: {message: count} }
      end
    end

    protected

    def topic_params
      params.require(:topic).permit(:subject, :posts_attributes => [[:text]])
    end

    def create_successful
      redirect_to [@forum, @topic], :notice => t("forem.topic.created")
    end

    def create_unsuccessful
      flash.now.alert = t('forem.topic.not_created')
      render :action => 'new'
    end

    def destroy_successful
      flash[:notice] = t("forem.topic.deleted")

      redirect_to @topic.forum
    end

    def destroy_unsuccessful
      flash.alert = t("forem.topic.cannot_delete")

      redirect_to @topic.forum
    end

    def subscribe_successful
      flash[:notice] = t("forem.topic.subscribed")
      redirect_to forum_topic_url(@topic.forum, @topic)
    end

    def unsubscribe_successful
      flash[:notice] = t("forem.topic.unsubscribed")
      redirect_to forum_topic_url(@topic.forum, @topic)
    end

    private
    def find_forum
      @forum = Forem::Forum.friendly.find(params[:forum_id])
      authorize! :read, @forum
    end

    def find_posts(topic)
      posts = topic.posts
      unless forem_admin_or_moderator?(topic.forum)
        posts = posts.approved_or_pending_review_for(forem_user)
      end
      @posts = posts
    end

    def find_topic
      begin
        @topic = forum_topics(@forum, forem_user).friendly.find(params[:id])
        authorize! :read, @topic
      rescue ActiveRecord::RecordNotFound
        flash.alert = t("forem.topic.not_found")
        redirect_to @forum and return
      end
    end

    def register_view(topic, user)
      topic.register_view_by(user)
    end

    def block_spammers
      if forem_user.forem_spammer?
        flash[:alert] = t('forem.general.flagged_for_spam') + ' ' +
            t('forem.general.cannot_create_topic')
        redirect_to :back and return
      end
    end

    def forum_topics(forum, user)
      if forem_admin_or_moderator?(forum)
        forum.topics
      else
        forum.topics.visible.approved_or_pending_review_for(user)
      end
    end
  end
end
