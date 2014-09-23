require 'will_paginate/array'

class ApplicationsController < ApplicationController

  def index
    @description = "Recent applications"

    if params[:authority_id]
      # TODO Handle the situation where the authority name isn't found
      @authority = Authority.find_by_short_name_encoded!(params[:authority_id])
      apps = @authority.applications
      @description << " from #{@authority.full_name_and_state}"
    else
      @description << " within the last #{Application.nearby_and_recent_max_age_months} months"
      apps = Application.where("date_scraped > ?", Application.nearby_and_recent_max_age_months.months.ago)
    end

    @applications = apps.paginate(:page => params[:page], :per_page => 30)
  end

  def address
    @description = "Hampshire Planning Applications"
    if request.post?
      @postcode = params[:postcode]
      @address = params[:address]
    end

    if !@postcode.nil?
      postcode = CGI::escape(@postcode.gsub(" ", ""))
      url = "#{MySociety::Config::get('MAPIT_URL')}/postcode/#{postcode}"
      begin
        content = HTTParty.get(url).body
        data = JSON.parse(content)
        lat = data["wgs84_lat"]
        lng = data["wgs84_lon"]
        if lat.nil? or lng.nil?
          @postcode_error = "Postcode is not valid."
        else
          redirect_to search_index_path({:lat => lat, :lng => lng})
        end
      rescue SocketError, Errno::ETIMEDOUT, JSON::ParserError
        @postcode_error = "Postcode is not valid."
      end
    elsif !@address.nil?
      address = CGI::escape(@address)
      r = Location.geocode(address)
      if r.success
        redirect_to search_index_path({:lat => r.lat, :lng => r.lng})
      else
        @address_error = "Address not found"
      end
    end
  end

  # JSON api for returning the number of scraped applications per day
  def per_day
    authority = Authority.find_by_short_name_encoded!(params[:authority_id])
    respond_to do |format|
      format.js do
        render :json => authority.applications_per_day
      end
    end
  end

  def per_week
    authority = Authority.find_by_short_name_encoded!(params[:authority_id])
    respond_to do |format|
      format.js do
        render :json => authority.applications_per_week
      end
    end
  end

  def search
    # TODO: Fix this hacky ugliness
    if request.format == Mime::HTML
      per_page = 30
    else
      per_page = Application.per_page
    end

    @q = params[:q]
    if @q
      @applications = Application.search @q, :fields => [:description],
                                                 :order => {:date_scraped => :desc},
                                                 :page => params[:page], :limit => per_page,
                                                 :highlight => {:tag => '<span class="match">'}
      @rss = search_applications_path(:format => "rss", :q => @q, :page => nil)
    end
    @description = @q ? "Search: #{@q}" : "Search"

    respond_to do |format|
      format.html
      format.rss { render "index", :format => :rss, :layout => false, :content_type => Mime::XML }
    end
  end

  # not currently used by anything
  def search_autocomplete
    render json: Application.search(params[:q], fields: [:address], autocomplete: true, limit: 10).map(&:address).uniq
  end

  def show
    # First check if there is a redirect
    redirect = ApplicationRedirect.find_by_application_id(params[:id])
    if redirect
      redirect_to :id => redirect.redirect_application_id
      return
    end

    @application = Application.find(params[:id])
    @nearby_count = @application.find_all_nearest_or_recent.count
    @comment = Comment.new
    # Required for new email alert signup form
    @alert = Alert.new(:address => @application.address)

    respond_to do |format|
      format.html
    end
  end

  def nearby
    # First check if there is a redirect
    redirect = ApplicationRedirect.find_by_application_id(params[:id])
    if redirect
      redirect_to :id => redirect.redirect_application_id
      return
    end

    @sort = params[:sort]
    @rss = nearby_application_url(params.merge(:format => "rss", :page => nil))

    # TODO: Fix this hacky ugliness
    if request.format == Mime::HTML
      per_page = 30
    else
      per_page = Application.per_page
    end

    @application = Application.find(params[:id])
    case(@sort)
    when "time"
      @applications = @application.find_all_nearest_or_recent.paginate :page => params[:page], :per_page => per_page
    when "distance"
      @applications = Application.unscoped do
        @application.find_all_nearest_or_recent.paginate :page => params[:page], :per_page => per_page
      end
    else
      redirect_to :sort => "time"
      return
    end

    respond_to do |format|
      format.html { render "nearby" }
      format.rss { render "api/index", :format => :rss, :layout => false, :content_type => Mime::XML }
    end
  end
end
