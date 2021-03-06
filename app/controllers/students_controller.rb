class StudentsController < ApplicationController
  
  before_filter  :authenticate_admin!
  before_action :set_student, only: [:show, :edit, :update, :destroy]
  
  def index
    @students = Student.all
    set_sessions_to_nil()
  end

  def new
    @source_options = Source.all.map{|s| [s.name, s.id]}
    @student = Student.new
    set_sessions_to_nil()
  end

  def show
    #@dtreeString = session[:dtreeString]
    @classname = session[:classname]
    @wordCount = session[:wordCount]
    @number_of_groups = session[:numberOfGroups]
    @correct = session[:correctlyClassified]
    @wrong = session[:wronglyClassified]
    @percentages = Array.new
    @percentages = session[:percentages]
    @percentage = session[:percentage]
    @totalTestInstances = session[:totalTestInstances]
    @names = Array.new
    @names = session[:name]
    @id = session[:student_id]
    
    @startedEvaluation = session[:startedEvaluation]
    
  end

  def create
    @student = Student.new(student_params)

    respond_to do |format|
      if @student.save
        format.html{redirect_to @student, notice: 'Student was successfully created.'}
        format.json{render :show, status: :created, location: @student}
        my_file = @student.essay
        path_to_save_csv = Rails.root.join('app','models','csv_files', "MainDataSet.csv").to_s
        process_initial_essay(my_file, path_to_save_csv)
      else
        format.html{render :new}
        format.json{render json: @student.errors, status: :unprocessable_entity}
      end
    end
  end
  
  def edit
    @source_options = Source.all.map{|s| [s.name, s.id]}
    set_sessions_to_nil
  end

  def update
    @student = Student.new(student_params)
    respond_to do |format|
      if @student.save
        #code
        format.html{redirect_to @student, notice: 'Student was successfully updated.'}
        format.json{render :show, status: :created, location: @student}
        my_file = @student.essay
        path_to_save_csv = Rails.root.join('app','models','csv_files', "MainDataSet.csv").to_s
        process_initial_essay(my_file, path_to_save_csv)
      else
        format.html{render :new}
        format.json{render json: @student.errors, status: :unprocessable_entity}
      end
    end
    set_sessions_to_nil()
  end
  
  def destroy
    #code
    @student.destroy
    respond_to do |format|
      format.html{redirect_to students_url, notice: 'Student was successfully deleted.'}
      format.json{head :no_content}
    end
  end
  
  def evaluateModel
    
    @startedEvaluation = 1
    session[:startedEvaluation] = @startedEvaluation
    
    loadEnvironment()
    
    
    #load the data using Java and Weka
    path = Rails.root.join('app','models','csv_files',"MainDataSet.csv").to_s
    train_src = Rjb::import("java.io.File").new(path)
    train_csvloader = Rjb::import("weka.core.converters.CSVLoader").new
    train_csvloader.setFile(train_src)
    train_data = train_csvloader.getDataSet
    
    
    # Testing data is input same way as testing data
    # Show path. Load via CSVLoader, setFile and getDataSet
    
    path = Rails.root.join('app','models','csv_files',"test.csv").to_s
    test_src = Rjb::import("java.io.File").new(path)
    test_csvloader = Rjb::import("weka.core.converters.CSVLoader").new
    test_csvloader.setFile(test_src)
    test_data = test_csvloader.getDataSet
    
    # NumericToNominal
    ntn = Rjb::import("weka.filters.unsupervised.attribute.NumericToNominal").new
    ntn.setInputFormat(train_data)
    ntn.setInputFormat(test_data)
    train_data = Rjb::import("weka.filters.Filter").useFilter(train_data, ntn)
    test_data = Rjb::import("weka.filters.Filter").useFilter(test_data, ntn)
    
    # Generate a classifier for the last index
    puts "Generate tree"
    
    tree = Rjb::import("weka.classifiers.trees.J48").new
    #tree = Rjb::import("weka.classifiers.trees.Tree").new
    
    train_data.setClassIndex(train_data.numAttributes() - 1)
    test_data.setClassIndex(test_data.numAttributes() - 1)
    tree.buildClassifier train_data
    
    puts "serialize model"
    sh = Rjb::import("weka.core.SerializationHelper")
    sh.write("/tmp/weka.model", tree);
    
    puts "deserialize model"
    sh = Rjb::import("weka.core.SerializationHelper")
    tree = sh.read("/tmp/weka.model");
    
    
    @dtreeString = tree.toString
    puts @dtreeString
      
    # Write out to a dot file
    @student_id = session[:student_id]
    @classname = train_data.classAttribute.toString.split(' ')[1] + @student_id.to_s
    
    session[:classname] = @classname
    
    graph = tree.graph.gsub(/Decision Tree {/, "Decision Tree {\n#{@classname}")
    File.open(Rails.root.join('app','assets','images','dots', @classname + '.dot').to_s,'w') { |f| f.write(graph) }
    `dot -Tgif < /home/ronnie/Rails/StylometryProject/app/assets/images/dots/#{@classname}.dot > /home/ronnie/Rails/StylometryProject/app/assets/images/gifs/#{@classname}.gif`
    
    puts "Generated tree for #{@classname}"
    
    preds_train = Array.new
    points_train_array = Array.new
    points_train = train_data.numInstances
    points_train.times do |instance|
      pred = tree.classifyInstance(train_data.instance(instance))
      point = train_data.instance(instance).toString
      point = point.split(",") << pred
      points_train_array << point
      preds_train << pred
      puts "#{point} : #{pred}"
    end
    
    preds_train = preds_train.to_s.gsub("]","")
    preds_train = preds_train.to_s.gsub("[","")
    preds_train = preds_train.to_s.gsub(" ","")
    preds_train = preds_train.split(",")
    #puts hash_function(preds_train)
    
    puts "Finished classifying train points"
    
    
    puts "*******************************************"
    
    
    preds_array = Array.new
    test_data.numInstances.times do |instance|
            pred = tree.classifyInstance(test_data.instance(instance))
            preds_array << pred
            puts "#{pred}"
    end
    
    puts "Finished prediction"
    
    puts preds_array
    
    preds_array = preds_array.to_s.gsub("]","")
    preds_array = preds_array.to_s.gsub("[","")
    preds_array = preds_array.to_s.gsub(" ","")
    preds_array = preds_array.split(",")
    
    session[:totalTestInstances] = preds_array.size

    hash1 = hash_function(preds_array)
    puts "Hash 1 : #{hash1}"
    
    # Populate an array with the id number of the students/authors
    arrayForIDS = Array.new
    0.upto(hash1.size - 1) {|j|
      0.upto(points_train_array.size - 1) {|i|
        if hash1.keys[j].to_i == points_train_array[i].last
          if arrayForIDS.include? points_train_array[i][-2]
            # Do nothing
          elsif points_train_array[i][-2].to_i <= Student.all.count
            arrayForIDS << points_train_array[i][-2]
          end 
        end
      }
    }
    
    # Create hash with key as student id and value as frequency
    idFreq = Hash.new(0)
    keys = arrayForIDS
    0.upto(arrayForIDS.size - 1){|i|
      idFreq[keys[i]] = hash1.values[i]  
    }
    
    puts "Array for IDS : #{arrayForIDS}"
    puts "ID Frequency : #{idFreq}"
    
    id_number = Array.new
    @name = Array.new
    
    corrects = Array.new
    @percentages = Array.new
    0.upto(idFreq.length - 1){|i|
      id_number[i] = idFreq.keys[i].to_i
      puts id_number[i]
      @name[i] = Student.find(id_number[i]).name.to_s
      corrects[i] = idFreq[keys[i]]
      if corrects[i].nil?
        corrects[i] = 0.0
      end
      puts corrects[i]
      @percentages[i] = (100 * corrects[i].to_f / preds_array.size.to_f).round(4)
    }
    
    session[:name] = @name
    session[:percentages] = @percentages


    
    # Calculate percentage
    studentid = session[:student_id].to_s
    @correct = idFreq[studentid].to_i
    @wrong = preds_array.size - @correct
    @percentage = (100 * @correct.to_f / preds_array.size).round(4)
    
    session[:correctlyClassified] = @correct
    session[:wronglyClassified] = @wrong
    session[:percentage] = @percentage
    
    
    puts "Does this printout?"
    
    redirect_to request.referer
    
  end
  
  private
  
  def student_params
    params.require(:student).permit(:source_id, :name, :essay)
  end
  
  def set_student
    @student = Student.find(params[:id])
    session[:student_id] = @student.id
  end
  
  def set_sessions_to_nil
    session[:dtreeString] = nil
    session[:classname] = nil
    session[:wordCount] = nil
    session[:numberOfGroups] = nil
    session[:correctlyClassified] = nil
    session[:wronglyClassified] = nil
    session[:percentage] = nil
    session[:totalTestInstances] = nil
    session[:name] = nil
    session[:startedEvaluation] = nil
    session[:percentages] = nil
  end
  
  # Returns an array with two elements.
  # The first element is the mode
  # The second element is the frquency of the mode
  def hash_function(array)
    counter = Hash.new(0)
    array.each {|i| counter[i] += 1}
    #mode_array = []
    #counter.each do |k,v|
    #  if v == counter.values.max
    #    mode_array << k
    #  end
    #end
    #v = counter[mode_array[0]]
    #mode_array << v
    #mode_array
    counter
  end
  
  def loadEnvironment
    #Load Java Jar
    dir = "./weka.jar"
    
    #Have Rjb load the jar file, and pass Java command line arguments
    Rjb::load(dir, jvmargs=["-Xmx1500m"])
  end
  
  def process_initial_essay(my_file, path_to_save_csv)
    
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
    
    #session[:wordCount] = @wordCount
    
    # Divide the essay into groups
    full_section = words.each_slice(GROUP_SIZE).to_a
    
    # Number of groups
    @number_of_groups = (@wordCount / GROUP_SIZE).ceil
    
    #session[:numberOfGroups] = @number_of_groups
    
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
    CSV.open(path_to_save_csv, "a+") do |csv|
      
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
