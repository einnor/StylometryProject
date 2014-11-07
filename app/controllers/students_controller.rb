class StudentsController < ApplicationController
  
  before_action :process_initial_essay, only: [:show, :edit, :update, :destroy]
  
  
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
    @student = Student.new(student_params)

    respond_to do |format|
      if @student.save
        format.html{redirect_to @student, notice: 'Student was successfully created.'}
        format.json{render :show, status: :created, location: @student}
      else
        format.html{render :new}
        format.json{render json: @student.errors, status: :unprocessable_entity}
      end
    end
  end

  def edit
    @source_options = Source.all.map{|s| [s.name, s.id]}
  end

  def update
    @student = Student.new(student_params)
    respond_to do |format|
      if @student.save
        #code
        format.html{redirect_to @student, notice: 'Student was successfully updated.'}
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
      format.html{redirect_to students_url, notice: 'Student was successfully deleted.'}
      format.json{head :no_content}
    end
  end
  
  private
  
  
  def set_params
    #code
    params.require(:student).permit(:source_id, :name, :essay)
  end
  
  def process_initial_essay
      @student = Student.find(params[:id])
      
    # Initialize a hash with a default of 0
    @countedWords = Hash.new(0)
    @section = Array.new
    @section_length = Array.new
      
    # code to read the essay file and convert it to lowercase
    # Currently only works with .txt files
    @file = @student
    @essay_file = @file.essay.read.downcase
      
      
    words = @essay_file.scan(/\w[\w']*/) #now catches contractions
    
    # Count words (keys) and increment their value 
    words.each {|word| @countedWords[word] += 1 }
    
    # Count the number of words in the essay  
    @wordCount = words.size
    
    
    # Number of groups
    @number_of_groups = (@wordCount / GROUP_SIZE).ceil
    
    # Break the essay into five parts
    full_section = words.each_slice(GROUP_SIZE).to_a
    
    # Create CSV headers
    # Populate it with the classifiers
    csv_headers = %w(the of at i)
    
    # Create a file with a path and unique name
    #path = "app/views/csv_files/" + @student.name.to_s + ".csv"
    #my_csv_file = File.open(path, "w+")
    
    @csv = CSV.open(Rails.root.join('app','models','csv_files', @student.name.to_s + ".csv").to_s, "wb") do |csv|
      csv << csv_headers
    end
    
    
    # Loop to assign sections and get their sizes
    1.upto(@number_of_groups) { |x|
      
      # Assign the sections of the full section to variable arrays
      # starting from index 0
      @section[x-1] = full_section[x-1]
      
      # Get the length of the sections and store them in an array
      # starting from index 0
      @section_length[x - 1] = @section[x - 1].size
      

    }

    
  end
  
  def words
    @countedWords.keys
  end
  
  def count(word)
    #will return 0 if 'word' not in 'countedWords' since 0 is the default value
    @countedWords[word]
  end
  
  def relativeFrequency(word)
    @countedWords[word] / @wordCount.to_f
    # count(word) / @wordCount.to_f
  end
  
  # set group size to be 90
  GROUP_SIZE = 25000.0
  
end
