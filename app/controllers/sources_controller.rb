class SourcesController < ApplicationController
  def index
    @sources = Source.all
  end

  def new
    @source = Source.new
  end

  def show
  end

  def create
    @source = Source.new(source_params)
    respond_to do |format|
      if @source.save
        #code
        format.html{redirect_to @source, notice: 'Source was successfully created.'}
        format.json{render :show, status: :created, location: @source}
      else
        format.html{render :new}
        format.json{render json: @source.errors, status: :unprocessable_entity}
      end
    end
      
  end

  def edit
    
  end

  def update
    respond_to do |format|
      if @source.update(source_params)
        #code
        format.html{redirect_to @source, notice: 'Source was successfully updated.'}
        format.json{render :show, status: :ok, location: @source}
      else
        format.html{render :edit}
        format.json{render json: @source.errors, status: :unprocessable_entity}
      end
      
    end
  end
  
  def destroy
    #code
    @source.destroy
    respond_to do |format|
      format.html{redirect_to sources_url, notice: 'Source was successfully deleted.'}
      format.json{head :no_content}
    end
  end
  
  private
  
  def source_params
    #code
    params.require(:source).permit(:name, :url)
  end
  
end
