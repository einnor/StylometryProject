class TestsController < ApplicationController
  
  before_filter  :authenticate_admin!
  before_action :load_student
  
  def index
  end
  
  def new
    @test = Test.new
    
    
  end

  def create
    @test = @student.tests.build(test_params)
    respond_to do |format|
      if @test.save
        my_file = @test.evaluate
        path_to_save_csv = Rails.root.join('app','models','csv_files', "test.csv").to_s
        process_test_essay(my_file, path_to_save_csv)
        format.html{redirect_to student_path(@student), notice: 'Test was successfully uploaded and processed.'}
      else
        format.html{render :new}
      end
    end
    
  end
  
  private
  
  def test_params
    #code
    params.require(:test).permit(:evaluate)
  end
  
  def load_student
  	@student = Student.find(params[:student_id])
  end
  
  def process_test_essay(my_file, path_to_save_csv)
    
    # Initialize a hash with a default of 0
    @countedWords = Hash.new(0)
    @section = Array.new
    @section_length = Array.new
    @counts = Array.new
    @classifierRelativeFrequency = Array.new
      
    # code to read the essay file and convert it to lowercase
    # Currently only works with .txt files
    my_file = my_file.read.downcase
        
    words = my_file.scan(/\w[\w']*/) #now catches contractions
    #words = words.gsub("'","")
    
    # Count words (keys) and increment their value 
    words.each {|word| @countedWords[word] += 1 }
    
    # Count the number of words in the essay  
    @wordCount = words.size
    
    session[:wordCount] = @wordCount
    
    # Divide the essay into groups
    full_section = words.each_slice(GROUP_SIZE).to_a
    
    # Number of groups
    @number_of_groups = (@wordCount / GROUP_SIZE).ceil
    
    session[:numberOfGroups] = @number_of_groups
    
    # Read classifiers from the classifier csv file
    file = (File.read(Rails.root.join('app','models','concerns','stopwords.txt').to_s))
    @csv_headers_modified = file
    @csv_headers_modified = @csv_headers_modified.gsub("'","")
    # Put the classifiers in an array
    @csv_headers = file.split(" ")
    @csv_headers_modified = @csv_headers_modified.split(" ")
    
    # Create a hash to store the relative frequencies of the classifiers
    1.upto(@number_of_groups) { |x|
      @classifierRelativeFrequency[x-1] = Hash.new(0)
    }
    
    # Open  test csv file and add the classifiers as headers
    CSV.open(path_to_save_csv, "wb") do |csv|
      
      csv << @csv_headers_modified
      
      # Loop to assign sections and get their sizes
      1.upto(@number_of_groups) { |x|
        
        # Assign the sections of the full section to variable arrays
        # starting from index 0
        @section[x-1] = full_section[x-1]
        
        # Get the length of the sections and store them in an array
        # starting from index 0
        @section_length[x - 1] = @section[x - 1].size
        
        # Create a hash for statistical analysis
        @counts[x-1] = Hash.new(0)
        
        # Add words to hash and increments count
        @section[x - 1].each {|word|
          @counts[x - 1][word] += 1  
        }
        
        # Calculate the relative frequency of the features in each section
        1.upto(@csv_headers.size - 1) { |c|   
          @classifierRelativeFrequency[x-1]["#{@csv_headers[c-1]}"] = (100 * @counts[x-1]["#{@csv_headers[c-1]}"].to_f / @section_length[x-1].to_f).round(3)
        }
        
        # Add the id of the author as the value of the class
        @classifierRelativeFrequency[x-1].merge!("class" => @student.id)
        
        # Add the relative frequencies to the csv file
        csv << @classifierRelativeFrequency[x-1].values.to_a
      }
 
    end
  end
  # set group size to be 90
  GROUP_SIZE = 90.0
end
