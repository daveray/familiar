require "java"
require "clojure-1.3.0.jar"

module Familiar

  # map some_func to clojure.core/some-func
  def self.method_missing(meth, *args, &block)
    #puts "Missing #{meth}"
    m = Java::clojure.lang.RT.var("clojure.core", meth.to_s.gsub("_", "-"))
    if m.is_bound?
      m.invoke(*args)
    else
      super
    end
  end

  #############################################################################
  # Functions

  class Callable 
    include Java::java.util.concurrent.Callable
    def initialize(callable)
      @callable = callable
    end

    def call
      @callable.call
    end
  end

  class Fn < Java::clojure.lang.AFn
    def initialize &block
      @block = block
    end

    def invoke(*args)
      @block.call *args
    end
  end

  def self.fn(p = nil, &code)
    if block_given?
      Fn.new &code
    else
      Fn.new &p
    end 
  end

  #############################################################################
  # Seqs

  def self.lazy_seq(&code)
    Java::clojure.lang.LazySeq.new(Familiar.fn(code))
  end

  #############################################################################
  # Atoms

  def self.atom?(v)
    v.is_a? Java::clojure.lang.Atom
  end

  class Java::ClojureLang::Atom
    def swap!(&code)
      swap(Familiar.fn(code))
    end

    def reset!(v)
      reset(v)
    end
  end

  #############################################################################
  # Refs and STM

  def self.dosync(&code)
    Java::clojure.lang.LockingTransaction.runInTransaction(Callable.new(code))
  end

  class Java::ClojureLang::Ref
    def alter(&code)
      java_send :alter, 
                [Java::clojure.lang.IFn.java_class, 
                 Java::clojure.lang.ISeq.java_class],
                Familiar.fn(code),
                nil
    end

    def commute(&code)
      java_send :commute, 
                [Java::clojure.lang.IFn.java_class, 
                 Java::clojure.lang.ISeq.java_class],
                Familiar.fn(code),
                nil
    end
  end

  #############################################################################
  # Agents

  class Java::ClojureLang::Agent
    def send_(&code)
      Familiar.send(self, Familiar.fn(code))
    end

    def send_off(&code)
      Familiar.send_off(self, Familiar.fn(code))
    end
  end
  

  def self.future(&code)
    Java::clojure.lang.Agent.soloExecutor.submit(Callable.new(code))
  end

end


