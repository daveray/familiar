module Familiar

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

  def self.fn(p)
    Fn.new &p
  end

end
