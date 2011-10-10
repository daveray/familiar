_My Ruby-meta-fu isn't that strong. In fact, this might be a terrible idea. Suggestions welcome._

Want to use Clojure's persistent, lazy data structures and concurrency primitives, but afraid of parentheses? Try it from Ruby.

Tested on JRuby 1.6.4 with Clojure 1.3.0.

# Usage

    require 'familiar'

Functions in `clojure.core` are mapped to the `Familiar` module, replacing hyphens with underscores:

    (clojure.core/hash-map "a" 1 "b" 2) 
   
becomes:

    Familiar.hash_map "a", 1, "b" 2

Some functions have additional Ruby sugar. See below.

Use `Familiar.with` if you don't feel like writing `Familiar` over and over:

    Familiar.with do
      reduce fn {|acc,v| acc + v}, 0, range(100)
    end
    => 4950

# Functions
Make a function from a proc or lambda:

    irb> Familiar.fn(lambda {|v| v * 2}).invoke(4)
    => 8

or just a block:

    irb> Familiar.fn {|v| v * 2}.invoke(4)
    => 8

# Persistent data structures


    # Create a vector
    v = Familiar.vector 1, 2, 3, 4
    v.nth 2 
    w = v.assoc 2 "hi"

    # Create a map
    v = Familiar.hash_map "a", 1, "b", 2
    w = v.assoc "c", 3
    w["c"] -> 3

# Atoms

    a = Familiar.atom(99)
    a.swap! |v|
      v + 1
    end
    a.deref -> 100
    a.reset! 101
    a.deref -> 101

# Refs and STM

    r = Familiar.ref(99)
    Familiar.dosync do
      r.alter {|v| v + 1}
    end
    r.deref -> 100

# Agents

    a = Familiar.agent(99)
    a.send_ do |v|
      java.lang.Thread.sleep 10000
      v + 1
    end
    a.deref -> 99
    # ... 10 seconds later ...
    a.deref -> 100

Note that it's `send_`, not `send` since that conflicts with the built-in Ruby method with that name.

# Sequences

Here's how you can make a lazy sequence

    def my_range(n)
      Familiar.lazy_seq do
        if n == 0
          nil
        else
          Familiar.cons n, my_range(n - 1)
        end
      end
    end

Use `clojure.core/reduce` to convert to a Ruby vector:

    irb> Familiar.reduce Familiar.fn {|acc,v| acc << v}, [], Familiar.range(5)
    => [0, 1, 2, 3, 4]

# Futures

Make a future:

    f = Familiar.future do
      puts "I'm run on some other thread and return a value later"
      "return value"
    end

    ...

    f.get -> "return value"

# Examples

    # Primes example from clojure docs
    # http://clojuredocs.org/clojure_core/clojure.core/reduce
    x = Familiar.with do
      reduce fn { |primes,number|
              if some(vars.zero?, map(fn {|x| number % x}, primes))
                primes
              else
                conj(primes, number)
              end
            },
            vector(2),
            take(100, iterate(vars.inc, 3))
    end
    Familiar.println x
    => [2 3 5 7 11 13 17 19 23 29 31 ... 67 71 73 79 83 89 97 101]

