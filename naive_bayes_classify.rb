#!/usr/bin/ruby
# encoding = utf-8
#
# Last modified:	2011-11-22 16:08
# Filename:		naive_bayes_classify.rb
# Description: 朴素贝叶斯分类器主程序

require 'pathname'
require "./lib//naive_bayes.rb"
require './lib/lib_trollop.rb'

opts = Trollop::options do
    version "naive_bayes 1.0.0 (c) 2011 MI&T LAB in HIT"
    banner <<-EOS
naive_bayes_classify is a document classify programme.

Usage:
    naive_bayes_classify [options] <Dirname>+
where [options] are:
EOS
    opt :train, "Train a model from a Dir", :type => String
    opt :test, "Test a dir from Mode", :type => String
    opt :model, "Model name for test or the output of train", :type => String
    opt :thres, "Threshold value for Naive Bayes Classify",:default=> 1.5
end

Trollop::die :train, "must exist" unless File.exist?(opts[:train]) if opts[:train]
Trollop::die :test, "must exist" unless File.exist?(opts[:test]) if opts[:test]
Trollop::die :model, "must exist" unless File.exist?(opts[:model]) if opts[:test]

def walk_dir(path_str)
    path = Pathname.new(path_str)
    path.children.each do |entry|
        if entry.directory? then
            yield entry.to_s.gsub!(/^.*\//, "")
        end
    end
end

def walk_document main_dir, child_dir
    total_dir = main_dir.gsub(/\/$/, "")
    total_dir << "\/" << child_dir
    path = Pathname.new(total_dir)
    path.children.each do |entry|
        if entry.directory?
            walk_document(main_dir, entry) {|x| yield(x)}
        elsif entry.file?
            yield entry
        end
    end
end

def walk_testdir dir
    path = Pathname.new(dir)
    path.children.each do |entry|
        if entry.directory?
            walk_testdir(entry) {|x| yield(x)}
        elsif entry.file?
            yield entry
        end
    end
end

def train opts
    categories = []
    walk_dir(opts[:train]) do |dirname|
        categories << dirname
    end
    naivebayes_train = NaiveBayes.new
    naivebayes_train.train_initialize(categories)
    puts "Training ..."
    categories.each do |category|
        walk_document(opts[:train], category) do |document|
            naivebayes_train.train document, category
        end
    end
    naivebayes_train.writemodel opts[:model]
end

def test opts
    naivebayes_test = NaiveBayes.new
    naivebayes_test.test_initialize opts[:model], opts[:thres]
    walk_testdir(opts[:test]) do |document|
        puts "#{document.to_s}:\t#{naivebayes_test.classify document}"
    end
end

train opts if opts[:train]
test opts if opts[:test]
