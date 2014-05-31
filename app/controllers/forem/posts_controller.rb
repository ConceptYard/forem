module Forem
  class PostsController < Forem::ApplicationController
    #before_filter :authenticate_forem_user
    before_filter :restrict_access!
    before_filter :find_topic, except: [:latest_posts]
    before_filter :reject_locked_topic!, :only => [:create]
    before_filter :block_spammers, :only => [:new, :create]
    before_filter :authorize_reply_for_topic!, :only => [:new, :create]
    before_filter :authorize_edit_post_for_forum!, :only => [:edit, :update]
    before_filter :find_post_for_topic, :only => [:edit, :update, :destroy]
    before_filter :ensure_post_ownership!, :only => [:destroy]
    before_filter :authorize_destroy_post_for_forum!, :only => [:destroy]

    require 'will_paginate/array'

    def new
      @post = @topic.posts.build
      find_reply_to_post

      if params[:quote] && @reply_to_post
        @post.text = view_context.forem_quote(@reply_to_post.text)
      elsif params[:quote] && !@reply_to_post
        flash[:notice] = t("forem.post.cannot_quote_deleted_post")
        redirect_to [@topic.forum, @topic]
      end
    end

    def create
      @post = @topic.posts.build(post_params)
      @post.user = forem_user

      respond_to do |format|
        if @post.save
          format.html { create_successful }
          format.json { render json: { message: "Post created" } }
        else
          format.html { create_failed }
          format.json { render json: { message: "Post failed" } }
        end
      end
    end

    def edit
    end

    def update
      respond_to do |format|
        if @post.owner_or_admin?(forem_user) && @post.update_attributes(post_params)
          format.html { update_successful }
          format.json { render json: { message: "Post updated" } }
        else
          format.html { update_failed }
          format.json { render json: { message: "Updated failed" } }
        end
      end
    end

    def destroy
      respond_to do |format|
        if @post.destroy
          format.html { destroy_successful }
          format.json { render json: { message: "Post deleted" } }
        else
          format.json { render json: { message: "Deletion failed" } }
        end
      end
    end

    def latest_posts
      @posts = Forem::Post.all.limit(100).sort_by(&:updated_at).reverse.paginate(:page => params[:page], :per_page => 5)
      respond_to do |format|
        format.html
        format.json { render json: @posts }
      end
    end

    private

    def post_params
      params.require(:post).permit(:text, :reply_to_id)
    end

    def authorize_reply_for_topic!
      authorize! :reply, @topic
    end

    def authorize_edit_post_for_forum!
      authorize! :edit_post, @topic.forum
    end

    def authorize_destroy_post_for_forum!
      authorize! :destroy_post, @topic.forum
    end

    def create_successful
      flash[:notice] = t("forem.post.created")
      redirect_to forum_topic_url(@topic.forum, @topic, pagination_param => @topic.last_page)
    end

    def create_failed
      params[:reply_to_id] = params[:post][:reply_to_id]
      flash.now.alert = t("forem.post.not_created")
      render :action => "new"
    end

    def destroy_successful
      if @post.topic.posts.count == 0
        @post.topic.destroy
        flash[:notice] = t("forem.post.deleted_with_topic")
        redirect_to [@topic.forum]
      else
        flash[:notice] = t("forem.post.deleted")
        redirect_to [@topic.forum, @topic]
      end
    end

    def update_successful
      redirect_to [@topic.forum, @topic], :notice => t('edited', :scope => 'forem.post')
    end

    def update_failed
      flash.now.alert = t("forem.post.not_edited")
      render :action => "edit"
    end

    def ensure_post_ownership!
      unless @post.owner_or_admin? forem_user
        flash[:alert] = t("forem.post.cannot_delete")
        redirect_to [@topic.forum, @topic] and return
      end
    end

    def find_topic
      @topic = Forem::Topic.friendly.find params[:topic_id]
    end

    def find_post_for_topic
      @post = @topic.posts.find params[:id]
    end

    def block_spammers
      if forem_user.forem_spammer?
        flash[:alert] = t('forem.general.flagged_for_spam') + ' ' +
                        t('forem.general.cannot_create_post')
        redirect_to :back
      end
    end

    def reject_locked_topic!
      if @topic.locked?
        flash.alert = t("forem.post.not_created_topic_locked")
        redirect_to [@topic.forum, @topic] and return
      end
    end

    def find_reply_to_post
      @reply_to_post = @topic.posts.find_by_id(params[:reply_to_id])
    end
  end
end
