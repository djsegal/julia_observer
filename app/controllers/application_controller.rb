class ApplicationController < ActionController::Base
  include Pagy::Backend

  def set_packages package_scope
    unless request.format.json?
      if params[:sort].present? && params[:order].present?
        package_scope = package_scope.order(params[:sort] => params[:order])
      else
        if params[:sort] == "name"
          package_scope = package_scope.order(params[:sort] => :asc)
        elsif params[:sort].present?
          package_scope = package_scope.order(params[:sort] => :desc)
        else
          if @category.present? && @category.name == "Trending"
            package_scope = package_scope.order(updated: :desc)
          else
            package_scope = package_scope.order(stars: :desc)
          end
        end
      end
    end

    cur_search = params[:s] || params[:search]

    if cur_search.present?
      if request.format.json?
        byebug
        package_scope = package_scope.quick_search(cur_search)
      else
        package_scope = package_scope.full_search(cur_search)
      end
    end

    @pagy, @packages = pagy_countless(
      package_scope, link_extra: 'data-remote="true"'
    )
  end
end
