class Twictures < Application

  def show
    @twicture = Twicture.find_by_status(params[:id])
    raise NotFound unless @twicture
    display @twicture
  end

  def new
    only_provides :html
    @twicture = Twicture.new(params[:twicture])
    render
  end

  def create
    @twicture = Twicture.find_or_create_by_twitter_url(params[:twicture])
    if @twicture.save
      redirect url(:twicture, @twicture)
    else
      flash[:error] = "Something bad happened." if flash[:error] == ''
      render :new
    end
  end

end
