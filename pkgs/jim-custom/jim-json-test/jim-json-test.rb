#! /usr/bin/env ruby

require 'rubygems'
require 'json'

json = '{"name": "Jim Pick", "year_born": 1970}'
puts json
puts JSON.parse(json).inspect;

