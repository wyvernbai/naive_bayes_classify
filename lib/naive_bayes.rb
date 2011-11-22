########################################################
# Last modified:	2011-10-24 21:56
# Filename:		naive_bayes.rb
# Description: 朴素贝叶斯分类器
# Dependent:    需要xml-simple
# 安装: sudo gem install xml-simple
########################################################

require 'builder'
require 'iconv'
require 'xmlsimple'

class NaiveBayes

    #=>初始化实例(阀值默认为1.5)
    def initialize
        @words = Hash.new
        @total_words = 0
        @categories_documents = Hash.new
        @total_documents = 0
        @categories_words = Hash.new

        #=>构造停止词hash表
        @common_words = COMMON_WORDS.gsub("\n", ' ').split
    end

    def train_initialize categories

        categories.each do |category|
            @words[category] = Hash.new
            @categories_documents[category] = 0
            @categories_words[category] = 0
        end
    end

    def test_initialize modelname, threshold_values=1.5
        loadmodel modelname
        @threshold_values = threshold_values
        @common_words = COMMON_WORDS.gsub("\n", ' ').split
    end

    #=>统计一个文件中单词出现的频率
    def word_count filename
        word_hash = Hash.new
        ic = Iconv.new('UTF-8//IGNORE', 'UTF-8')
        bigstring = ic.iconv(IO.read(filename))
        bigstring.gsub!(/[^\w\s]/," ")
        bigstring.split.each do |word|
            word.downcase!
            unless @common_words.include?(word)
                word_hash[word] ||= 0
                word_hash[word] += 1
            end
        end
        return word_hash
    end

    #=>在已知word HASH和category的基础上生成model
    def train document, category
        #puts "#{document} => Model ... "
        word_count(document).each do |key, value|
            @words[category][key] ||= 0
            @words[category][key] += value
            @total_words += value
            @categories_words[category] += value
        end
        #p @words
        @categories_documents[category] += 1
        @total_documents += 1
    end

    #=>将训练结果以xml文件的形式存储
    def writemodel modelname
        puts "Writing Model ..."
        xml = Builder::XmlMarkup.new(:indext=>2)
#        xml.instruct! :xml, :encoding => "UTF-8"
        xml.naive_bayes do
            xml.total_word @total_words
            xml.total_documents @total_documents
            @categories_documents.each_key do |category|
                xml.each_category do
                    xml.category category
                    xml.categories_documents @categories_documents[category]
                    xml.categories_words @categories_words[category]
                    xml.feature do
                        @words[category].each do |key, value|
                            xml.word key
                            xml.value value
                        end
                    end
                end
            end
        end

        open(modelname, 'w') do |f|
            f.puts xml.target!
        end
    end

    #=> test之前必须先加载model. xml parser 用到了“xml-simple”,如果没有这个ruby库，须自行安装"sudo gem install xml-simple"
    def loadmodel modelname
        puts "Loading model...."

        model = XmlSimple.xml_in(modelname)#["naive_bayes"]
        @total_words = model["total_word"][0].to_i
        @total_documents = model["total_documents"][0].to_i
        model["each_category"].each do |details|
            category = details["category"][0]
            @categories_documents[category] = details["categories_documents"][0].to_i
            @categories_words[category] = details["categories_words"][0].to_i
            i = 0
            @words[category] = Hash.new
            details["feature"][0]["word"].each do |word|
                @words[category][word] = details["feature"][0]["value"][i].to_i
                i += 1
            end
        end
    end

    #=>朴素贝叶斯分类器
    def classify document, default='unknown'
        sorted = probabilities(document).sort {|a,b| a[1]<=>b[1]}
        best,second_best = sorted.pop, sorted.pop
        return best[0] if best[1].to_f/second_best[1].to_f > @threshold_values
        return default  #=>最好和次好的比值低于阀值则返回“unknown”
    end

    def probabilities document
        probabilities = Hash.new
        @categories_documents.each_key do |category|
            probabilities[category] = probability(category, document)
        end
        return probabilities
    end

    #=>求先验概率
    def category_probability category
        @categories_documents[category].to_f/@total_documents.to_f
    end

    #=>求类条件概率(防止类条件概率出现0的情况，在每一个单词的count基础上+1)
    def word_probability category, word
        if @words[category].has_key? word then
            result = (@words[category][word].to_f + 1)/@categories_words[category].to_f
        else
            result = 1.0/@categories_words[category].to_f
        end
        return result
    end

    #=>打分(文件中所有单词对应的类条件概率的乘积)
    def doc_probability category, document
        doc_probability_value = 1
        word_count(document).each do |word|
            doc_probability_value *= word_probability(category, word[0])
        end
        return doc_probability_value
    end

    #=> 根据贝叶斯方程求概率
    def probability category, document
        doc_probability(category, document) * category_probability(category)
    end

    COMMON_WORDS = "a able about above abroad according accordingly
across actually adj after afterwards again against ago ahead ain't
all allow allows almost alone along alongside already also although
always am amid amidst among amongst an and another any anybody anyhow
anyone anything anyway anyways anywhere apart appear appreciate
appropriate are aren't around as a's aside ask asking associated at
available away awfully b back backward backwards be became because become
becomes becoming been before beforehand begin behind being believe
below beside besides best better between beyond both brief but by c
came can cannot cant can't caption cause causes certain certainly
changes clearly c'mon co co. com come comes concerning consequently
consider considering contain containing contains corresponding could
couldn't course c's currently d dare daren't definitely described
despite did didn't different directly do does doesn't doing done
don't down downwards during e each edu eg eight eighty either else
elsewhere end ending enough entirely especially et etc even ever
evermore every everybody everyone everything everywhere ex exactly
example except f fairly far farther few fewer fifth first five
followed following follows for forever former formerly forth forward
found four from further furthermore g get gets getting given gives
go goes going gone got gotten greetings h had hadn't half happens
hardly has hasn't have haven't having he he'd he'll hello help hence
her here hereafter hereby herein here's hereupon hers herself he's
hi him himself his hither hopefully how howbeit however hundred i
i'd ie if ignored i'll i'm immediate in inasmuch inc inc. indeed
indicate indicated indicates inner inside insofar instead into
inward is isn't it it'd it'll its it's itself i've j just k keep
keeps kept know known knows l last lately later latter latterly
least less lest let let's like liked likely likewise little look
looking looks low lower ltd m made mainly make makes many may maybe
mayn't me mean meantime meanwhile merely might mightn't mine minus
miss more moreover most mostly mr mrs much must mustn't my myself
n name namely nd near nearly necessary need needn't needs neither
never neverf neverless nevertheless new next nine ninety no nobody
non none nonetheless noone no-one nor normally not nothing
notwithstanding novel now nowhere o obviously of off often oh ok
okay old on once one ones one's only onto opposite or other others
otherwise ought oughtn't our ours ourselves out outside over overall
own p particular particularly past per perhaps placed please plus
possible presumably probably provided provides q que quite qv r rather
rd re really reasonably recent recently regarding regardless regards
relatively respectively right round s said same saw say saying says
second secondly see seeing seem seemed seeming seems seen self selves
sensible sent serious seriously seven several shall shan't she she'd
she'll she's should shouldn't since six so some somebody someday
somehow someone something sometime sometimes somewhat somewhere soon
sorry specified specify specifying still sub such sup sure t take taken
taking tell tends th than thank thanks thanx that that'll thats that's
that've the their theirs them themselves then thence there thereafter
thereby there'd therefore therein there'll there're theres there's
thereupon there've these they they'd they'll they're they've thing
things think third thirty this thorough thoroughly those though three
through throughout thru thus till to together too took toward towards
tried tries truly try trying t's twice two u un under underneath undoing
unfortunately unless unlike unlikely until unto up upon upwards us use
used useful uses using usually v value various versus very via viz vs w
want wants was wasn't way we we'd welcome well we'll went were we're
weren't we've what whatever what'll what's what've when whence whenever
where whereafter whereas whereby wherein where's whereupon wherever whether
which whichever while whilst whither who who'd whoever whole who'll whom
whomever who's whose why will willing wish with within without wonder won't
would wouldn't x y yes yet you you'd you'll your you're yours yourself
yourselves you've z zero"

end
