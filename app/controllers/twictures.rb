class Twictures < Application

  def show
    @twicture = Twicture.find_or_create_by_status(params[:id])
    raise NotFound unless @twicture
    if @twicture
      if params[:send_file]
        redirect("/i/#{@twicture.status}.gif")
        # send_file(Merb.root + '/public/' + @twicture.image_path, {:content_type => 'image/gif', :disposition => 'inline'}) 
      else
        display @twicture
      end
    else
      flash[:error] = "Something bad happened." if flash[:error] == ''
      render :new
    end
  end

  def new
    only_provides :html
    @twicture = Twicture.new(params[:twicture])
    render
  end

  def create
    @twicture = Twicture.find_or_create_by_twitter_url(params[:twicture])
    if !@twicture.new_record? || @twicture.save
      redirect url(:twicture, @twicture)
    else
      flash[:error] = "Something bad happened."
      render :new
    end
  end

end
