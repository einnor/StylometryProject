class StudentsController < ApplicationController
  
  before_action :set_student, only: [:show, :edit, :update, :destroy]
  
  
  def index
    @students = Student.all
  end

  def new
    @source_options = Source.all.map{|s| [s.name, s.id]}
    @student = Student.new
  end

  def show
  end

  def create
    #@student.source_id = @source.id
    @student = Student.new(student_params)
    respond_to do |format|
      if @student.save
        #code
        format.html{redirect_to @student, notice: 'Student was successfully created.'}
        format.json{render :show, status: :created, location: @student}
      else
        format.html{render :new}
        format.json{render json: @student.errors, status: :unprocessable_entity}
      end
    end
  end

  def edit
  end

  def update
    #@student.source_id = @source.id
    @student = Student.new(student_params)
    respond_to do |format|
      if @student.save
        #code
        format.html{redirect_to @student, notice: 'Student was successfully created.'}
        format.json{render :show, status: :created, location: @student}
      else
        format.html{render :new}
        format.json{render json: @student.errors, status: :unprocessable_entity}
      end
    end
  end
  
  def destroy
    #code
    @student.destroy
    respond_to do |format|
      format.html{redirect_to student_url, notice: 'Student was successfully deleted.'}
      format.json{head :no_content}
    end
  end
  
  private
  #
  #def set_source
  #  #code
  #  @source = Source.find(params[:id])
  #  @sources = Source.all
  #end
  
  def set_student
      @student = Student.find(params[:id])
  end
  
  def student_params
    #code
    params.require(:source).permit(:source_id, :name, :essay)
  end
  
end
