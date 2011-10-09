Want to use Clojure's persistent, lazy data structures and concurrency primitives, but afraid of parentheses? Try it from Ruby.

Use the Clojure runtime from Ruby, JRuby in particular.

# Usage

    require 'familiar'

Functions in `clojure.core` are mapped to the `Familiar` module, replacing hyphens with underscores:

    (clojure.core/hash-map "a" 1 "b" 2) 
   
becomes:

    Familiar.hash_map "a", 1, "b" 2

Some functions have additional Ruby sugar. See below.

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

