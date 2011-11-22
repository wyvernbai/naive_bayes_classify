#!/usr/bin/ruby
# encoding = utf-8
#
# Last modified:	2011-11-22 16:09
# Filename:		result_analyze.rb
# Description: 朴素贝叶斯分类器结果分析

require "./lib/lib_trollop.rb"

opts = Trollop::options do
    version "result_analyze 1.0.0 (c) 2011 MI&T LAB in HIT"
    banner <<-EOS
result_analyze is a naive_bayes_classify result analyze programme.

Usage:
    result_analyze [options] <filename>
where [options] are:
EOS
    opt :file, "Output file of \"naive_bayes_classify\"", :type => String
end

Trollop::die :file, "must exist" unless File.exist?(opts[:file]) if opts[:file]

relation_found = Hash.new       #=> 相关而且识别到的
relation_notfound = Hash.new    #=> 相关的但是没有识别出来的
norelation_found = Hash.new     #=> 不相关但是识别错误的

IO.read(opts[:file]).split(/\n/).each do |item|
    standard = item.split(/\//)[-2]
    probabily = item.split(/\t/)[-1]
    if probabily != "unknown" then
        if probabily == standard then
            relation_found[standard] ||= 0
            relation_found[standard] += 1
        else
            relation_notfound[standard] ||= 0
            relation_notfound[standard] += 1
            norelation_found[probabily] ||= 0
            norelation_found[probabily] += 1
        end
    else
        relation_notfound[standard] ||= 0
        relation_notfound[standard] += 1
    end
end

relation_found.each do |key, value|
    precision = value.to_f / (value + norelation_found[key]).to_f
    recall = value.to_f / (value + relation_notfound[key]).to_f
    f = precision * recall * 2 / (precision + recall)       #=> F值
    puts "#{key}:\tprecision=>#{precision}\trecall=>#{recall}\tf=>#{f}"
end
