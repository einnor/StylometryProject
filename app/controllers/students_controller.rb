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
    @dtreeString = session[:dtreeString]
    @classname = session[:classname]
    @wordCount = session[:wordCount]
    @number_of_groups = session[:numberOfGroups]
    @correct = session[:correctlyClassified]
    @wrong = session[:wronglyClassified]
    @percentage = session[:percentage]
    @totalTestInstances = session[:totalTestInstances]
  end

  def create
    @student = Student.new(student_params)

    respond_to do |format|
      if @student.save
        format.html{redirect_to @student, notice: 'Student was successfully created.'}
        format.json{render :show, status: :created, location: @student}
        process_initial_essay()
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
  
  def trainModel
    loadEnvironment()
    
    # Path to the dataset
    path = Rails.root.join('app','models','csv_files',"MainDataSet.csv").to_s
    
    fanfics_src = Rjb::import("java.io.File").new(path)
    fanfics_csvloader = Rjb::import("weka.core.converters.CSVLoader").new
    fanfics_csvloader.setFile(fanfics_src)
    fanfics_data = fanfics_csvloader.getDataSet
    
    # NominalToString
    nts = Rjb::import("weka.filters.unsupervised.attribute.NominalToString").new
    nts.setOptions '-C last'.split(' ')
    nts.setInputFormat(fanfics_data)
    fanfics_data = Rjb::import("weka.filters.Filter").useFilter(fanfics_data, nts)
    
    # NumericToNominal
    ntn = Rjb::import("weka.filters.unsupervised.attribute.NumericToNominal").new
    ntn.setInputFormat(fanfics_data)
    fanfics_data = Rjb::import("weka.filters.Filter").useFilter(fanfics_data, ntn)
    
    # Generate a classifier for the last index
    puts "Generate tree"
    
    $TREE = Rjb::import("weka.classifiers.trees.J48").new
    #$TREE.setOptions '-B 10 -E -3'.split(' ')
    fanfics_data.setClassIndex(fanfics_data.numAttributes() - 1)
    $TREE.buildClassifier(fanfics_data)
    
    print $TREE
    
    @dtreeString = $TREE.toString
    puts @dtreeString
    
    # Write out to a dot file
    @classname = fanfics_data.classAttribute.toString.split(' ')[1]
    graph = $TREE.graph.gsub(/Decision Tree {/, "Decision Tree {\n#{@classname}")
    File.open(Rails.root.join('app','assets','images','dots', @classname + '.dot').to_s,'w') { |f| f.write(graph) }
    `dot -Tgif < /home/ronnie/Rails/StylometryProject/app/assets/images/dots/#{@classname}.dot > /home/ronnie/Rails/StylometryProject/app/assets/images/gifs/#{@classname}.gif`    
    
    puts "Generated tree for #{@classname}"
    
    fanfics_data.numInstances.times do |instance|
      pred = $TREE.classifyInstance(fanfics_data.instance(instance))
      puts pred
    end
    
    puts "Finished classifying these points"
    puts "*********************************************"
    
      
    redirect_to request.referer
    
  end
  
  
  def evaluateModel
    
    loadEnvironment()
    
    # Path to the dataset
    path = Rails.root.join('app','models','csv_files',"MainDataSet.csv").to_s
    
    fanfics_src = Rjb::import("java.io.File").new(path)
    fanfics_csvloader = Rjb::import("weka.core.converters.CSVLoader").new
    fanfics_csvloader.setFile(fanfics_src)
    fanfics_data = fanfics_csvloader.getDataSet
    
    # NominalToString
    nts = Rjb::import("weka.filters.unsupervised.attribute.NominalToString").new
    nts.setOptions '-C last'.split(' ')
    nts.setInputFormat(fanfics_data)
    fanfics_data = Rjb::import("weka.filters.Filter").useFilter(fanfics_data, nts)
    
    # NumericToNominal
    ntn = Rjb::import("weka.filters.unsupervised.attribute.NumericToNominal").new
    ntn.setInputFormat(fanfics_data)
    fanfics_data = Rjb::import("weka.filters.Filter").useFilter(fanfics_data, ntn)
    
    # Generate a classifier for the last index
    puts "Generate tree"
    
    $TREE = Rjb::import("weka.classifiers.trees.J48").new
    fanfics_data.setClassIndex(fanfics_data.numAttributes() - 1)
    $TREE.buildClassifier(fanfics_data)
    
    @dtreeString = $TREE.toString
    puts @dtreeString
    
    session[:dtreeString] = @dtreeString
    
    # Write out to a dot file
    @classname = fanfics_data.classAttribute.toString.split(' ')[1]
    
    session[:classname] = @classname
    
    graph = $TREE.graph.gsub(/Decision Tree {/, "Decision Tree {\n#{@classname}")
    File.open(Rails.root.join('app','assets','images','dots', @classname + '.dot').to_s,'w') { |f| f.write(graph) }
    `dot -Tgif < /home/ronnie/Rails/StylometryProject/app/assets/images/dots/#{@classname}.dot > /home/ronnie/Rails/StylometryProject/app/assets/images/gifs/#{@classname}.gif`
    
    
    puts "Generated tree for #{@classname}"
    
    preds_train = Array.new
    points_train = fanfics_data.numInstances
    points_train.times do |instance|
      pred = $TREE.classifyInstance(fanfics_data.instance(instance))
      point = fanfics_data.instance(instance).toString
      point = point.split(",")
      preds_train << pred
      puts "#{point} : #{pred}"
    end
    
    preds_train = preds_train.to_s.gsub("]","")
    preds_train = preds_train.to_s.gsub("[","")
    preds_train = preds_train.to_s.gsub(" ","")
    preds_train = preds_train.split(",")
    puts modeAndFrequency(preds_train)
    
    puts "Finished classifying these points"
    puts "*********************************************"
  
    # Follow same procedure for training
    #Load the test
    path = Rails.root.join('app','models','csv_files',"test.csv").to_s
    test_src = Rjb::import("java.io.File").new(path)
    test_csvloader = Rjb::import("weka.core.converters.CSVLoader").new
    test_csvloader.setFile(test_src)
    test_data = test_csvloader.getDataSet
    
    # NominalToString
    nts = Rjb::import("weka.filters.unsupervised.attribute.NominalToString").new
    nts.setOptions '-C last'.split(' ')
    nts.setInputFormat(test_data)
    test_data = Rjb::import("weka.filters.Filter").useFilter(test_data, nts)
    
    # NumericToNominal
    ntn = Rjb::import("weka.filters.unsupervised.attribute.NumericToNominal").new
    ntn.setInputFormat(test_data)
    test_data = Rjb::import("weka.filters.Filter").useFilter(test_data, ntn)
    
    test_data.setClassIndex(test_data.numAttributes() - 1)
    
    preds_test = Array.new
    points_test = test_data.numInstances
    points_test.times do |instance|
      pred = $TREE.classifyInstance(test_data.instance(instance))
      point = test_data.instance(instance).toString
      point = point.split(",")
      preds_test << pred
      puts "#{point} : #{pred}"
    end
    
    preds_test = preds_test.to_s.gsub("]","")
    preds_test = preds_test.to_s.gsub("[","")
    preds_test = preds_test.to_s.gsub(" ","")
    preds_test = preds_test.split(",")
    
    session[:totalTestInstances] = preds_test.size

    mAF = modeAndFrequency(preds_test)
    puts mAF
    
    # Calculate percentage
    @correct = mAF.last
    @wrong = preds_test.size - @correct
    @percentage = (100 * @correct.to_f / preds_test.size).round(4)
    
    session[:correctlyClassified] = @correct
    session[:wronglyClassified] = @wrong
    session[:percentage] = @percentage
    
    puts "Does this printout?"
    
    redirect_to request.referer
    
  end
  
  private
  
  def student_params
    params.require(:student).permit(:source_id, :name, :essay, :essayEvaluate)
  end
  
  def set_student
    @student = Student.find(params[:id])
  end
  
  # Returns an array with two elements.
  # The first element is the mode
  # The second element is the frquency of the mode
  def modeAndFrequency(array)
    counter = Hash.new(0)
    array.each {|i| counter[i] += 1}
    mode_array = []
    counter.each do |k,v|
      if v == counter.values.max
        mode_array << k
      end
    end
    v = counter[mode_array[0]]
    mode_array << v
    mode_array
  end
  
  def loadEnvironment
    #Load Java Jar
    dir = "./weka.jar"
    
    #Have Rjb load the jar file, and pass Java command line arguments
    Rjb::load(dir, jvmargs=["-Xmx1500m"])
  end
  
  def process_initial_essay
    
    # Initialize a hash with a default of 0
    @countedWords = Hash.new(0)
    @section = Array.new
    @section_length = Array.new
    @counts = Array.new
    @classifierRelativeFrequency = Array.new
      
    # code to read the essay file and convert it to lowercase
    # Currently only works with .txt files
    @file = @student
    @essay_file = @file.essay.read.downcase
        
    words = @essay_file.scan(/\w[\w']*/) #now catches contractions
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
    #@csv_headers_modified = file
    #@csv_headers_modified = @csv_headers_modified.gsub("'","")
    # Put the classifiers in an array
    @csv_headers = file.split(" ")
    #@csv_headers_modified = @csv_headers_modified.split(" ")
    
    # Create a hash to store the relative frequencies of the classifiers
    1.upto(@number_of_groups) { |x|
      @classifierRelativeFrequency[x-1] = Hash.new(0)
    }
    
    # Open MainDataSet a csv file and add the classifiers as headers
    CSV.open(Rails.root.join('app','models','csv_files', "MainDataSet.csv").to_s, "a+") do |csv|
      
      #csv << @csv_headers_modified
      
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
  GROUP_SIZE = 90.0
  
  # loading some java classes
  Filter = Rjb::import("weka.filters.Filter")
  NullStemmer = Rjb::import("weka.core.stemmers.NullStemmer")
  WordTokenizer = Rjb::import("weka.core.tokenizers.WordTokenizer")
  AttributeSelection = Rjb::import("weka.filters.supervised.attribute.AttributeSelection")
  
end
