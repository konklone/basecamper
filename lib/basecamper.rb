require 'fileutils'
require 'basecamp'

class Basecamper
  
  attr_reader :basecamp, :projects, :times, :person_id, :config
  
  def initialize
    initialize_data!
    
    # need to make booleans a special case and transform there here forevermore
    ["use_ssl"].each do |key| 
      @config[key] = true if @config[key] == "true"
      @config[key] = false if @config[key] == "false"
    end
    # defaults
    {"rounding" => 15, "minutes_logged" => 0}.each_pair {|key, value| @config[key] ||= value}
    
    @basecamp = Basecamp.new @config.url, @config.user_name, @config.password, @config.use_ssl
    
    # set up a couple of attr_readers
    @person_id = @config.person_id
    @projects = @config.projects
  end
  
  
  # main API
  
  def configure!(url, user_name, password, use_ssl)
    write_config("url" => url, "user_name" => user_name, "password" => password, "use_ssl" => use_ssl)
    test_basecamp!
  end
  
  def set!(key, value)
    write_config(key.to_s => value)
    test_basecamp! if key.in? ["url", "user_name", "password", "use_ssl"]
  end
  
  def start!(start_time = nil)
    return if started?
    
    write_config("start_time" => (start_time.to_time || Time.now))
  end
  
  def stop!(message, end_time = nil)
    return unless started?
    
    minutes = minutes_elapsed(end_time).round_to(@config.rounding.to_i)
    
    write_config("start_time" => nil, "minutes_logged" => 0)
    log_time(":#{minutes}", message)
  end
  
  def cancel!
    return unless started? or paused?
    
    write_config("start_time" => nil, "minutes_logged" => 0)
  end
  
  def pause!
    return unless started?
    
    write_config("start_time" => nil, "minutes_logged" => minutes_elapsed)
  end
  
  def log_time(duration, message, project = nil)
    project_id = project_id(project || current_project)
    return unless project_id
    
    save @basecamp.log_time(project_id, @person_id, Time.now, duration, message)
  end
  
  def delete_time(time_id = nil)
    time = time_id ? find_time(time_id) : @times.first
    return unless time
    
    @basecamp.delete_time(time.id, time.project_id)
    @times.delete time
    write_times
    
    time
  end
  
  # secondary API
  
  def current_project
    @config.current_project.capitalize_all
  end
  
  def configured?
    @config.configured
  end
  
  def test_basecamp!
    @basecamp = Basecamp.new(@config.url, @config.user_name, @config.password, @config.use_ssl)
    write_config("configured" => @basecamp.test_auth)
    sync_basecamp if configured?
  end
  
  def sync_basecamp
    puts "Initializing, may take a few seconds..."
    $stdout.flush if $stdout and $stdout.respond_to? :flush
    get_person(@config.user_name)
    get_projects
  end
  
  def started?
    !@config.start_time.nil?
  end
  
  def paused?
    !started? and (@config.minutes_logged > 0)
  end
  
  def minutes_elapsed(end_time = nil)
    if started?
      @config.minutes_logged + (end_time || Time.now).minutes_since(start_time)
    else
      @config.minutes_logged
    end
  end
  
  def start_time
    @config.start_time
  end
  
  def project_name(project_id)
    @projects[project_id].capitalize_all
  end
  
  def project_id(name)
    @projects.invert[name.to_s.downcase]
  end
  
  def save(record)
    return unless record
    record = record.to_hash
    record.created_at = Time.now
    @times.unshift record
    prune_times
    write_times
    @times.first
  end
  
  def inspect
    config = @config.dup
    config.projects = config.projects.values.map {|name| name.capitalize_all}.join(", ")
    config.to_yaml.gsub(/^---/, "")
  end
  
  private
  
  def initialize_data!
    FileUtils.mkdir data_path if !File.exists? data_path
    if File.exists?(config_file)
      @config = YAML.load_file(config_file)
    else
      @config = {}
      write_config
    end
    
    if File.exists?(times_file)
      @times = YAML.load_file(times_file)
    else
      @times = []
      write_times
    end
    true
  end
  
  def config_file
    File.join data_path, "config.yml"
  end
  
  def times_file
    File.join data_path, "times.yml"
  end
  
  def data_path
    File.join ENV['HOME'], ".basecamper"
  end
  
  def get_projects
    @projects = {}
    @basecamp.projects.each {|project| @projects[project.id] = project.name.downcase}
    write_config("projects" => @projects)
  end
  
  def get_person(user_name)
    if record = basecamp.person(user_name)
      @person_id = record.id
      write_config("person_id" => @person_id)
    end
  end
  
  def find_time(id)
    @times.find {|time| time.id.to_s == id}
  end
  
  # keep only today's times
  def prune_times
    now = Time.now.strftime("%Y-%m-%d")
    @times.reject! {|time| time["date"].strftime("%Y-%m-%d") != now}
  end
  
  def write_config(params = {})
    params.each_pair {|key, value| @config[key] = value}
    File.open(config_file, "w") {|file| file.write(@config.to_yaml)}
  end
  
  def write_times
    File.open(times_file, "w") {|file| file.write(@times.to_yaml)}
  end
  
  
end


# Basecamp wrapper extensions

class Basecamp

  def log_time(project_id, person_id, date, hours, description = nil, todo_item_id = nil)
    entry = {"project_id" => project_id, "person_id" => person_id, "date" => date.to_s, "hours" => hours.to_s}
    entry["description"] = description if description
    entry["todo_item_id"] = todo_item_id if todo_item_id
    record "/time/save_entry", :entry => entry
  end
  
  def delete_time(id, project_id)
    record "/projects/#{project_id}/time/delete_entry/#{id}"
  end
  
  # overrides existing #person to accept an ID or a user_name - IDs of 0 will be interpreted as a user_name
  def person(identifier)
    if identifier.is_a? Fixnum or identifier.to_i > 0
      record "/contacts/person/#{identifier}"
    else # identifier is a username
      all_people.find {|person| person["user-name"] == identifier}
    end
  end
  
  def companies
    records "company", "/contacts/companies"
  end
  
  # Fetches all people from all companies and prunes for uniqueness
  def all_people
    companies.map do |company|
      records "person", "/contacts/people/#{company.id}"
    end.flatten
  end
  
  # tests credentials
  def test_auth
    begin
      projects
      true
    rescue
      false
    end
  end
  
  class Record
    def to_hash
      hash = {}
      self.attributes.each do |attr|
        hash[attr.undashify] = self[attr]
      end
      hash
    end
  end
  
end


# Core extensions

class String
  def to_time
    matches = self.match(/^(\d\d?)(:\d\d)?(am?|pm?)?$/i)
    return unless matches
    
    hour = matches[1].to_i
    minutes = matches[2] ? matches[2].gsub(/:/, "").to_i : 0
    meridian = matches[3]
    
    return unless hour > 0
    hour += 12 if meridian =~ /^p/ and hour < 12
    return unless hour <= 24
    
    now = Time.now
    Time.mktime(now.year, now.month, now.day, hour, minutes)
  end
  
  def capitalize_all(separator = " ")
    split(" ").map {|s| s.capitalize}.join(" ")
  end
  
  def blank?
    empty?
  end
  
  def dashify
    self.tr '_', '-'
  end
  
  def undashify
    self.tr '-', '_'
  end
end

class Time
  def to_time
    self
  end
  
  def minutes_since(time)
    ((self - time) / 60).ceil
  end
end

class NilClass
  def blank?
    true
  end
  
  def method_missing(method, *args)
    self
  end
end

class Hash
  def id
    method_missing :id
  end
  
  def method_missing(method, *args)
    if method.to_s =~ /=$/
      self[method.to_s.tr('=','')] = args.first
    else
      self[method.to_s]
    end
  end
end

class Object
  def in?(collection)
    collection.include? self
  end
end

class Fixnum
  def round_to(minutes)
    return self unless minutes > 0
    
    if self > 0 and self % minutes == 0
      self
    else
      self + (minutes - (self % minutes))
    end
  end
end

class Array
  def sum
    inject {|sum, x| sum + x}
  end
end