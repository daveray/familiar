#  Copyright (c) Dave Ray, 2011. All rights reserved.

#   The use and distribution terms for this software are covered by the
#   Eclipse Public License 1.0 (http://opensource.org/licenses/eclipse-1.0.php)
#   which can be found in the file epl-v10.html at the root of this 
#   distribution.
#   By using this software in any fashion, you are agreeing to be bound by
#   the terms of this license.
#   You must not remove this notice, or any other, from this software.

require "java"
require "clojure-1.3.0.jar"

module Familiar
  # TODO why do I have this again?
  module Vars
    def self.[] (ns, var)
      m = Java::clojure.lang.RT.var(ns, var.to_s.gsub("_", "-"))
      m.is_bound? ? m : nil
    end

    def self.method_missing(meth, *args, &block)
      self["clojure.core", meth] or super
    end
  end

  # Provides access to Clojure vars for when you need to use a Clojure
  # var without invoking it.
  #
  # Given a single argument, it's treated as a var in clojure.core. Two
  # argument form allows a particular namespace to be referenced.
  #
  # Examples:
  #
  #   Familiar[:inc]
  #   => #'clojure.core/inc
  #
  #   Familiar["clojure.set", :union]
  #   => #'clojure.set/union
  #
  #   Familiar.with do
  #     filter self[:even?], range(100)
  #   end
  #
  #   Familiar.with do
  #     require symbol("clojure.set")
  #     self["clojure.set", :union].invoke(hash_set(1, 2), hash_set(2, 3))
  #   end
  #
  def self.[] (ns, var = nil)
    if not var
      var = ns
      ns = "clojure.core"
    end
    Familiar::Vars[ns, var]
  end
 
  def self.method_missing(meth, *args, &block)
    #puts "Missing #{meth}"
    m = self[meth]
    if m
      m.invoke(*args)
    else
      super
    end
  end

  # Make inspect and to_s look right in irb
  [
   #Java::ClojureLang::LazySeq,
   Java::ClojureLang::PersistentVector,
   Java::ClojureLang::PersistentList,
   Java::ClojureLang::PersistentArrayMap,
   Java::ClojureLang::PersistentHashMap,
   Java::ClojureLang::PersistentHashSet,
   Java::ClojureLang::Symbol,
   Java::ClojureLang::Keyword,
   Java::ClojureLang::Atom,
   Java::ClojureLang::Ref,
   Java::ClojureLang::Agent,
   Java::ClojureLang::Var,
   Java::ClojureLang::Cons,
   Java::ClojureLang::ChunkedCons
   ].each do |x|
    x.class_eval do
      def to_s
        self.to_string
      end
      def inspect
        Familiar.pr_str self
      end
    end
  end

  [ Java::ClojureLang::LazySeq ].each do |x|
    x.class_eval do
      def inspect!
        Familiar.pr_str self
      end
    end
  end

  # Run a block of code without having to qualify everything in this module:
  #
  # Examples:
  # 
  #   # Here, reduce, fn, range are all from Clojure
  #   Familiar.with do
  #     reduce fn {|acc, x| acc + x}, range(100)
  #   end
  #
  def self.with(&block)
    instance_eval &block
  end

  #############################################################################
  # Functions

  # Wrap a Proc in a Java Callable
  class Callable 
    include Java::java.util.concurrent.Callable
    def initialize(callable)
      @callable = callable
    end

    def call
      @callable.call
    end
  end

  # JRuby impl of clojure fn
  class Fn < Java::clojure.lang.AFn
    def initialize &block
      @block = block
    end

    def invoke(*args)
      @block.call *args
    end
  end

  # Create a Clojure fn from a block
  #
  # Example:
  #   
  #   (fn [x] (+ x 1))
  #
  # is the same as:
  #
  #   Familiar.fn {|x| x + 1}
  #
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
    
    # Like clojure.core/swap! except block is used as update function 
    def swap!(&code)
      swap(Familiar.fn(code))
    end

    # Same as clojure.core/reset!
    def reset!(v)
      reset(v)
    end
  end

  #############################################################################
  # Refs and STM

  # Run a block in an STM transaction
  def self.dosync(&code)
    Java::clojure.lang.LockingTransaction.runInTransaction(Callable.new(code))
  end

  # Add some helpers to refs
  class Java::ClojureLang::Ref

    # Like clojure.core/alter except block is used as update function
    def alter(&code)
      java_send :alter, 
                [Java::clojure.lang.IFn.java_class, 
                 Java::clojure.lang.ISeq.java_class],
                Familiar.fn(code),
                nil
    end

    # Like clojure.core/commute except block is used as update function
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

    # Like clojure.core/send except block is used as update function
    def send_(&code)
      Familiar.send(self, Familiar.fn(code))
    end

    # Like clojure.core/send-off except block is used as update function
    def send_off(&code)
      Familiar.send_off(self, Familiar.fn(code))
    end
  end
  
  #############################################################################
  # Misc

  # Pass a block to clojure.core/future
  def self.future(&code)
    Java::clojure.lang.Agent.soloExecutor.submit(Callable.new(code))
  end

  #############################################################################
  # REPL
  if $0 != __FILE__
    Familiar.with do
      self.require symbol("clojure.repl")
    end

    def self.find_doc(s)
      self["clojure.repl", :find_doc].invoke(s)
    end

    # Print docs for he given string, symbol, etc.
    #
    # Examples:
    #
    #   > Familiar.doc :reduce
    #   ... prints docs for clojure.core/reduce ...
    #
    #   > Familiar.doc "clojure.repl/source"
    #   ... prints docs for clojure.repl/source ...
    def self.doc(s)
      self.with do
        Familiar.eval read_string("(clojure.repl/doc #{s})")
      end
    end

    # Same as Familiar.doc, but prints the *source code* for the given
    # input.
    def self.source(s)
      self.with do
        Familiar.eval read_string("(clojure.repl/source #{s})")
      end
    end
  end
end


