module Forem
  class CategoriesController < Forem::ApplicationController
    helper 'forem/forums'
    load_and_authorize_resource :class => 'Forem::Category'

    def index
      redirect_to "/discussions#{'.json' if request.format == 'json'}"
    end

    def show
      respond_to do |format|
        format.html
        format.json { render json: @category.forums }
      end
    end

  end
end
