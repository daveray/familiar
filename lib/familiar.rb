require "java"
require "clojure-1.3.0.jar"

require 'familiar/fn'
require 'familiar/atom'
require 'familiar/ref'
require 'familiar/seq'

module Familiar

  def self.future(&code)
    Java::clojure.lang.Agent.soloExecutor.submit(Callable.new(code))
  end

  def self.print(v)
    puts(Java::clojure.lang.RT.print_string(v))
  end

    
  def self.hash_map(*args)
    Java::clojure.lang.RT.map(*args)
  end

  def self.hash_set(*args)
    Java::clojure.lang.RT.set(*args)
  end

  def self.vector(*args)
    Java::clojure.lang.RT.vector(*args)
  end

end


