class StudentsController < ApplicationController
  
  #require 'rjb'
  
  before_action :set_student, only: [:show, :edit, :update, :destroy]
  before_action :pushToCsv, only: [:show, :edit, :update, :destroy, :analysisAndPredictionDecision, :analysisAndPredictionAi4r, :analysisAndPredictionWeka]
  before_action :process_initial_essay, only: [:show, :edit, :update, :destroy]
  before_action :analysisAndPredictionDecision, only: [:show, :edit, :update, :destroy]
  before_action :analysisAndPredictionAi4r, only: [:show, :edit, :update, :destroy]
  before_action :analysisAndPredictionWeka, only: [:show, :edit, :update, :destroy]
  
  
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
  
  ## Custom create
  # def new_evaluation
  #  @source_options = Source.all.map{|s| [s.name, s.id]}
  #end
  #
  #
  #def create_evaluation
  #  @student = Student.new(set_evaluate_params)
  #
  #  respond_to do |format|
  #    if @student.save
  #      format.html{redirect_to @student, notice: 'Student was successfully created.'}
  #      format.json{render :show, status: :created, location: @student}
  #    else
  #      format.html{render :new}
  #      format.json{render json: @student.errors, status: :unprocessable_entity}
  #    end
  #  end
  #end

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
  
  
  def student_params
    #code
    params.require(:student).permit(:source_id, :name, :essay, :essayEvaluate)
  end
  
  def set_student
    #code
    @student = Student.find(params[:id])
  end
  
  def process_initial_essay
    #@student = Student.find(params[:id])
      
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
    
    # Count words (keys) and increment their value 
    words.each {|word| @countedWords[word] += 1 }
    
    # Count the number of words in the essay  
    @wordCount = words.size
    
    # Divide the essay into groups
    full_section = words.each_slice(GROUP_SIZE).to_a
    
    # Number of groups
    @number_of_groups = (@wordCount / GROUP_SIZE).ceil
    
    # Read classifiers from the classifier csv file
    file = (File.read(Rails.root.join('app','models','concerns','stopwords.txt').to_s))
    file = file.gsub("'",'')
    
    # Put the classifiers in an array
    @csv_headers = file.split(" ")
    
    # Create a hash to store the relative frequencies of the classifiers
    1.upto(@number_of_groups) { |x|
      @classifierRelativeFrequency[x-1] = Hash.new(0)
    }
    
    # Create a csv file and add the classifiers as headers
    CSV.open(Rails.root.join('app','models','csv_files', @student.name.to_s + "_"+ @student.id.to_s + "_.csv").to_s, "wb") do |csv|
      csv << @csv_headers
      
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
          
          # Calculate the relative frequency of the classifiers in each section
          1.upto(@csv_headers.size) { |c|   
            @classifierRelativeFrequency[x-1]["#{@csv_headers[c-1]}"] = (100 * @counts[x-1]["#{@csv_headers[c-1]}"].to_f / @section_length[x-1].to_f).round(3)
          }
  
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
  
  def pushToCsv
    ##code
    #@file_array = Array.new
    #
    #CSV.foreach(Rails.root.join('app','models','csv_files', @student.name.to_s + ".csv").to_s) do |row|
    #  @file_array << row
    #end

    #@attributes = @file_array.delete_at(0)
    #@file_array.delete_at(0)
    #
    #@test = @file_array[8]
    #@test = @test.flatten.collect { |i| i.to_f }
    #@test = @test#.insert(-1,0.0)
    #0.upto(@file_array.size - 1) {|i|
    #  @file_array[i] = @file_array[i].insert(-1, 1.0)  
    #}
    #@training = @file_array.map{|arr| arr.map(&:to_f)}
    #
    #@training[0] = @training[0].insert('class')
    #0.upto(@training.size - 1) {|i|
    #  @training[i] = @training[i].insert(-1, 'unquestionable')  
    #}

  end
  
  # Method to construct a decision tree from the extracted data
  def analysisAndPredictionDecision    
    
    # This method has bugs
    ## Instantiate the tree, and train it based on the data (set default to '1')
    #dec_tree = DecisionTree::ID3Tree.new(@attributes, @training, 1, :continuous)
    #dec_tree.train
    #
    #@decision = dec_tree.predict(@test)
    #
    ## Graph the tree, save to 'discrete.png'
    #dec_tree.graph(Rails.root.join('app','assets','images', 'graphs') + "#{@student.name.to_s}_#{@student.id.to_s}_continuous")
    #
    
  end
  
  def analysisAndPredictionAi4r
    #code for Ai4r goes here
    #code
    #data_file = Rails.root.join('app','models','csv_files', @student.name.to_s + ".csv").to_s
    #data_set = Ai4r::Data::DataSet.load_csv_with_labels data_file
    #id3 = Ai4r::Classifiers::ID3.new.build(data_set)
    
  end
  
  def analysisAndPredictionWeka
      ##Load Java Jar
      #dir = "./weka.jar"
      #
      ##Have Rjb load the jar file, and pass Java command line arguments
      #Rjb::load(dir, jvmargs=["-Xmx1000M"])
      #
      #
      #
      ##load the data using Java and Weka
      ##fanfics_src = Rjb::import("java.io.File").new(ARGV[0])
      ##fanfics_src = Rjb::import("java.io.File").new(Rails.root.join('app','models','csv_files', @student.name.to_s + ".csv").to_s)
      ##fanfics_src = Rjb::import("java.io.File").new(Rails.root.join('app','models','csv_files', @student.name.to_s + "_"+ @student.id.to_s + "_.csv").to_s)
      #fanfics_src = Rjb::import("java.io.File").new("/home/ronnie/weka-3-7-11/data/breast-cancer.arff")
      #
      #
      #fanfics_csvloader = Rjb::import("weka.core.converters.CSVLoader").new
      #fanfics_csvloader.setFile(fanfics_src)
      #fanfics_data = Rjb::import("weka.core.Instances").new(fanfics_csvloader.getDataSet)
      #
      ## NominalToString
      #nts = Rjb::import("weka.filters.unsupervised.attribute.NominalToString").new
      #nts.setOptions '-C last'.split(' ')
      #nts.setInputFormat(fanfics_data)
      #fanfics_data = Rjb::import("weka.filters.Filter").useFilter(fanfics_data, nts)
      #
      ## Stemmer
      #nullstemmer = Rjb::import("weka.core.stemmers.NullStemmer").new
      #
      ## Tokenizer
      #wordtokenizer = Rjb::import("weka.core.tokenizers.WordTokenizer").new
      #wordtokenizer.setOptions ["-delimiters", "\" \\r\\n\\t.,;:\\\'\\\"()?!\""]
      #
      ## StringToWordVector
      #stwv = Rjb::import("weka.filters.unsupervised.attribute.StringToWordVector").new
      #stwv.setOptions '-R first-last -W 1000 -prune-rate -1.0 -N 0 -L -M 3 -stopwords /home/ronnie/Rails/ruby-weka/stopwords.txt"'.split(' ')
      #stwv.setStemmer nullstemmer
      #stwv.setTokenizer wordtokenizer
      #stwv.setInputFormat(fanfics_data)
      #fanfics_data = Rjb::import("weka.filters.Filter").useFilter(fanfics_data, stwv)
      #
      ## NumericToNominal
      #ntn = Rjb::import("weka.filters.unsupervised.attribute.NumericToNominal").new
      #ntn.setInputFormat(fanfics_data)
      #fanfics_data = Rjb::import("weka.filters.Filter").useFilter(fanfics_data, ntn)
      #
      #
      #
      #
      #  
      #
      #
      #
      ## Generate a classifier for each index
      #puts "Generating trees"
      #(0..fanfics_data.numAttributes - 1).each do |i|
      #  
      #  #make id3 classifier (C4.5)
      #  obj = Rjb::import("weka.classifiers.trees.J48")
      #  dtree = obj.new
      #  #dtree.setOptions '-B 10 -E -3'.split(' ')
      #  fanfics_data.setClassIndex(i)
      #  dtree.buildClassifier fanfics_data
      #  @dtreeString = dtree.toString
      #  
      #  
      #  # Write out to a dot file
      #  classname = "dot_file" #fanfics_data.classAttribute.toString.split(' ')[1]
      #  graph = dtree.graph.gsub(/digraph DTree {/, "digraph DTree {\n#{classname}")
      #  File.open(Rails.root.join('app','models','dots', classname.to_s + ".dot").to_s, 'w') { |f| f.write(graph) }
      #  `dot -Tgif < /home/ronnie/Rails/StylometryProject/app/models/dots/#{classname}.dot > /home/ronnie/Rails/StylometryProject/app/models/gifs/#{classname}.gif`
      #  
      #  puts "Generated tree for #{classname}"
      #
      #  ## ADTree
      #  #adtree = Rjb::import("weka.classifiers.trees.ADTree").new
      #  #adtree.setOptions '-B 10 -E -3'.split(' ')
      #  #fanfics_data.setClassIndex(i)
      #  #adtree.buildClassifier fanfics_data
      #  
      #  ## Write out to a dot file
      #  #classname = fanfics_data.classAttribute.toString.split(' ')[1]
      #  #graph = adtree.graph.gsub(/digraph ADTree {/, "digraph ADTree {\n#{classname}")
      #  #File.open('dots/'+classname+'.dot', 'w') { |f| f.write(graph) }
      #  #`dot -Tgif < dots/#{classname}.dot > gifs/#{classname}.gif`
      #  #
      #  #puts "Generated tree for #{classname}"
      #  
      #  # Examine the particular datapoints
      #  points = fanfics_data.numInstances
      #  points.times {|instance|
      #    theclass = dtree.classifyInstance(fanfics_data.instance(instance))
      #    point = fanfics_data.instance(instance).toString
      #    puts "#{point} \t #{theclass}"
      #  }
      #end
      #
      #
      ##
      ### Attribute Selection
      ##attsel = Rjb::import('weka.attributeSelection.AttributeSelection').new
      ##
      ### Attribute Evaluator
      ###cfssubseteval = Rjb::import('weka.attributeSelection.CfsSubsetEval').new
      ##lsa = Rjb::import('weka.attributeSelection.LatentSemanticAnalysis').new
      ##lsa.setOptions '-R 0.95 -A 1000'.split(' ')
      ##
      ### Search Method
      ###greedysearch = Rjb::import('weka.attributeSelection.GreedyStepwise').new
      ###greedysearch.setOptions '-T -1.7976931348623157E308 -N -1'.split(' ')
      ###greedysearch.setSearchBackwards true
      ##ranker = Rjb::import('weka.attributeSelection.Ranker').new
      ##ranker.setOptions '-T -1.7976931348623157E308 -N -1'.split(' ')
      ##
      ### Run 'em
      ###attsel.setEvaluator(cfssubseteval)
      ##attsel.setEvaluator(lsa)
      ###attsel.setSearch(greedysearch)
      ##attsel.setSearch(ranker)
      ###attsel.SelectAttributes(fanfics_data)
      ##attsel.SelectAttributes(fanfics_data)
      ##
      ##fanfics_data = attsel.reduceDimensionality(fanfics_data)
      ##topics = fanfics_data.toString.scan(/^@.*/)
      ##topics[1..-1].each_with_index do |topic, i|
      ##  words = topic.gsub(/^@attribute '/,'').gsub(/ numeric$/,'').gsub('+','').scan(/(-?[0-9\.]+)([^-0-9\.]+)/).collect{|a,b| [a.to_f, b]}.sort{|a,b| b[0]<=>a[0]}
      ##  print "Topic ##{i}:   "
      ##  words[0..5].each {|w| print "#{w[1]} "}
      ##  puts ''
      ##end
      ###selected_attributes.each do |i|
      ###  puts fanfics_data.attribute(i).name
      ###end
      
  end
  
  # set group size to be 90
  GROUP_SIZE = 90.0
  
  # loading some java classes
  Filter = Rjb::import("weka.filters.Filter")
  NullStemmer = Rjb::import("weka.core.stemmers.NullStemmer")
  WordTokenizer = Rjb::import("weka.core.tokenizers.WordTokenizer")
  AttributeSelection = Rjb::import("weka.filters.supervised.attribute.AttributeSelection")
  
end
