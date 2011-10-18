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

require "set"

module Familiar
  # Represents a Clojure namespace. Don't create directly. Use
  # Familiar.ns(...)
  #
  # All methods calls map to calling the same var in this namespace as
  # a function. Underscores are automatically converted to hyphens.
  #
  # See:
  #   Familiar.ns()
  class NS
    def initialize(ns)
      @ns = ns
    end

    # Require this namespace so functions and vars are accessible.
    # TODO should this be automatic?
    #
    # Returns self
    def require(*args)
      #puts "Requiring #{@ns}"
      r = Familiar[:require]
      if args.empty?
        r.invoke(Familiar.symbol(@ns))
      else
        r.invoke(*args)
      end
      self
    end

    # Lookup a var in this namespace.
    #
    # Examples:
    #
    #   Familiar.ns("clojure.java.io")[:reader]
    def [] (var)
      m = Java::clojure.lang.RT.var(@ns, var.to_s.gsub("_", "-"))
      m.is_bound? ? m : nil
    end

    # All methods calls map to calling the same var in this namespace as
    # a function. Underscores are automatically converted to hyphens.
    def method_missing(meth, *args, &block)
      #puts "Missing #{@ns}/#{meth}"
      m = self[meth]
      if m
        m.invoke(*args)
      else
        super
      end
    end

    # TODO This gets in the way of clojure.core/eval. One fix might be
    # NS < BasicObject. Not sure yet.
    undef eval
  end

  # Returns a Clojure NS by name. When given no argument, returns clojure.core.
  #
  # This is generally useful because it provides access to Clojure vars 
  # for when you need to use a Clojure var without invoking it. Combine
  # with NS.[] for this effect.
  #
  # Returns an instance of Familiar::NS
  #
  # Examples:
  #
  #   # Require a namespace
  #   Familiar["clojure.set"].require
  #
  #   # Get the union function from clojure.set
  #   Familiar.ns("clojure.set")[:union]
  #   => #'clojure.set/union
  #
  #   Familiar.with do
  #     ns("clojure.set").require
  #     ns("clojure.set").union(hash_set(1, 2), hash_set(2, 3))
  #   end
  #   => #{1 2 3}
  #
  # See:
  #   Familiar.[]
  def self.ns (ns)
    # TODO cache namespaces?
    Familiar::NS.new(ns || "clojure.core")
  end

  # Lookup a var.
  #
  #   [ns, var] => #'ns/var
  #
  #   [var] => #'clojure.core/var
  #
  # This is useful if you need to pass an existing Clojure function to a 
  # higher-order function.
  # 
  # Note that there's significant overlap with Familiar.ns().
  #
  # Examples:
  #
  #   # Get the inc function from core
  #   Familiar[:inc]
  #   => #'clojure.core/inc
  #
  #   # Get the union function from clojure.set
  #   Familiar["clojure.set", :union]
  #   => #'clojure.set/union
  #
  #   # Pass clojure.core/even? to clojure.core/filter
  #   Familiar.with do
  #     filter self[:even?], range(100)
  #   end
  #   => (0 2 4 6 ...)
  #
  #   Familiar.with do
  #     ns("clojure.set").require
  #     self["clojure.set", :union].invoke(hash_set(1, 2), hash_set(2, 3))
  #     # ... or ...
  #     ns("clojure.set").union(hash_set(1, 2), hash_set(2, 3))
  #   end
  #   => #{1 2 3}
  #
  # See:
  #   Familiar.ns()
  def self.[] (ns_name, var = nil)
    if not var
      var = ns_name
      ns_name = "clojure.core"
    end
    ns(ns_name)[var]
  end
 
  def self.method_missing(meth, *args, &block)
    ns(nil).send(meth, *args, &block)
  end

  # Make inspect and to_s look right in irb
  [Java::ClojureLang::PersistentVector,
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

  # LazySeq gets special treatment to avoid killing IRB with infinite seqs.
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

  # Create a lazy sequence with the code in the block.
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
  # Type conversions
  
  def self.to_clojure(v)
    v.respond_to?(:to_clojure) ? v.to_clojure : v
  end

  def self.to_ruby(v)
    v.respond_to?(:to_ruby) ? v.to_ruby : v
  end

  class ::Array
    def to_clojure
      f = Familiar
      f.vec(f.map f.fn {|x| f.to_clojure(x)}, self)
    end
  end

  class ::Hash
    def to_clojure
      f = Familiar
      f.into f.hash_map, map {|k,v| f.vector(f.to_clojure(k), f.to_clojure(v))} 
    end
  end
  
  class ::Set
    def to_clojure
      r = Familiar.hash_set()
      each do |v|
        r = Familiar.conj r, v
      end
      r
    end
  end

  class ::Symbol
    def to_clojure
      Familiar.keyword(to_s)
    end
  end

  class Java::ClojureLang::Keyword
    def to_ruby
      name.intern
    end
  end

  module ListToRuby
    def to_ruby
      r = []
      each do |v|
        r << Familiar.to_ruby(v)
      end
      r
    end
  end

  class Java::ClojureLang::PersistentVector
    include ListToRuby
  end

  class Java::ClojureLang::PersistentList
    include ListToRuby
  end

  class Java::ClojureLang::LazySeq
    include ListToRuby
  end

  module MapToRuby 
    def to_ruby
      r = {}
      each do |k,v|
        r[Familiar.to_ruby(k)] = Familiar.to_ruby(v)
      end
      r
    end
  end

  class Java::ClojureLang::PersistentArrayMap
    include MapToRuby
  end

  class Java::ClojureLang::PersistentHashMap
    include MapToRuby
  end

  class Java::ClojureLang::PersistentHashSet
    def to_ruby
      r = Set.new
      each do |v|
        r.add(Familiar.to_ruby(v))
      end
      r
    end
  end

  #############################################################################
  # REPL
  if $0 != __FILE__
    ns("clojure.repl").require

    def self.find_doc(s)
      ns("clojure.repl").find_doc s
    end

    # Print docs for the given string, symbol, etc.
    #
    # Examples:
    #
    #   > Familiar.doc :reduce
    #   ... prints docs for clojure.core/reduce ...
    #
    #   > Familiar.doc "clojure.repl/source"
    #   ... prints docs for clojure.repl/source ...
    def self.doc(s)
      self.eval read_string("(clojure.repl/doc #{s})")
    end

    # Same as Familiar.doc, but prints the *source code* for the given
    # input.
    def self.source(s)
      self.eval read_string("(clojure.repl/source #{s})")
    end
  end
end


