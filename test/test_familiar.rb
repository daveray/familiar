#  Copyright (c) Dave Ray, 2011. All rights reserved.

#   The use and distribution terms for this software are covered by the
#   Eclipse Public License 1.0 (http://opensource.org/licenses/eclipse-1.0.php)
#   which can be found in the file epl-v10.html at the root of this 
#   distribution.
#   By using this software in any fashion, you are agreeing to be bound by
#   the terms of this license.
#   You must not remove this notice, or any other, from this software.

require 'test/unit'
require 'familiar'

class FamiliarTest < Test::Unit::TestCase

  def test_can_require_a_namespace
    f = Familiar
    s = Familiar::NS.new("clojure.set")
    assert_equal s, s.require
    assert_equal f.hash_set(1, 2, 3), s.union(f.hash_set(1, 2), f.hash_set(3, 2))
  end

  def test_to_s_looks_right
    assert_equal '(1 2 3 4 5)', Familiar.list(1, 2, 3, 4, 5).to_s
    assert_equal '[1 2 3 4 5]', Familiar.vector(1, 2, 3, 4, 5).to_s
    assert_equal '{1 2, 3 4, 5 6}', Familiar.hash_map(1, 2, 3, 4, 5, 6).to_s
    assert_equal '#{1 2 3 4 5}', Familiar.hash_set(1, 2, 3, 4, 5).to_s
    assert_equal 'hi', Familiar.symbol("hi").to_s
    assert_equal ':hi', Familiar.keyword("hi").to_s
    assert Familiar.range(4).to_s =~ /^clojure\.lang\.LazySeq@\h+$/
    assert Familiar.atom('hi').to_s =~ /^clojure\.lang\.Atom@\h+$/
    assert Familiar.ref('hi').to_s =~ /^clojure\.lang\.Ref@\h+$/
    assert Familiar.agent('hi').to_s =~ /^clojure\.lang\.Agent@\h+$/
    assert Familiar[:identity].to_s =~ /^#'clojure\.core\/identity$/
    assert_equal '(1 2 3)', Familiar.cons(1, Familiar.list(2, 3)).to_s
    assert_equal '(1 2 3 4)', Familiar.rest(Familiar.range(5)).to_s
  end

  def test_inspect_looks_right
    assert_equal '(1 2 3 4 5)', Familiar.list(1, 2, 3, 4, 5).inspect
    assert_equal '[1 2 3 4 5]', Familiar.vector(1, 2, 3, 4, 5).inspect
    assert_equal '{1 2, 3 4, 5 6}', Familiar.hash_map(1, 2, 3, 4, 5, 6).inspect
    assert_equal '#{1 2 3 4 5}', Familiar.hash_set(1, 2, 3, 4, 5).inspect
    assert_equal 'hi', Familiar.symbol("hi").inspect
    assert_equal ':hi', Familiar.keyword("hi").inspect
    assert Familiar.atom('hi').inspect =~ /^#<Atom@\h+: "hi">$/
    assert Familiar.ref('hi').inspect =~ /^#<Ref@\h+: "hi">$/
    assert Familiar.agent('hi').inspect =~ /^#<Agent@\h+: "hi">$/
    assert Familiar[:identity].inspect =~ /^#'clojure\.core\/identity$/
    assert_equal '(1 2 3)', Familiar.cons(1, Familiar.list(2, 3)).inspect
    assert_equal '(1 2 3 4)', Familiar.rest(Familiar.range(5)).inspect
  end

  def test_can_force_lazyseqs_with_inspect!
    assert_equal '(0 1 2 3)', Familiar.range(4).inspect!
  end

  def test_can_get_vars_from_other_namespaces
    f = Familiar
    f.require f.symbol("clojure.set")
    union = f.ns("clojure.set")[:union]
    assert union
    assert_equal f.hash_set(1, 2, 3), union.invoke(f.hash_set(1, 2), f.hash_set(3, 2))
  end

  def test_can_create_a_function_from_a_lambda
    f = Familiar.fn(lambda {|x| x * 2 })
    assert f.is_a? Java::clojure.lang.IFn
    assert_equal 8, f.invoke(4)
  end

  def test_can_create_a_function_from_a_block
    f = Familiar.fn {|x| x * 2 }
    assert f.is_a? Java::clojure.lang.IFn
    assert_equal 8, f.invoke(4)
  end

  def test_can_create_a_list
    input = (1..100).to_a
    a = Familiar.list(*input)
    assert a.is_a? Java::clojure.lang.IPersistentList
    assert_equal input.count, a.count
    assert_equal 1, a.first
  end

  def test_can_create_a_vector
    a = Familiar.vector("a", "b", "c", "d")
    assert a.is_a? Java::clojure.lang.IPersistentVector
    assert_equal 4, a.count
    assert_equal "a", a.nth(0)
    assert_equal "b", a.nth(1)
    assert_equal "c", a.nth(2)
    assert_equal "d", a.nth(3)
  end

  def test_can_create_a_hash_map
    a = Familiar.hash_map("a", "b", "c", "d")
    assert a.is_a? Java::clojure.lang.IPersistentMap
    assert_equal "b", a["a"]
    assert_equal "d", a["c"]
  end

  def test_can_create_a_hash_set
    a = Familiar.hash_set("a", "b", "c", "d")
    assert a.is_a? Java::clojure.lang.IPersistentSet
    assert a.contains?("a")
    assert a.contains?("b")
    assert a.contains?("c")
    assert a.contains?("d")
  end

  def test_can_conj_on_a_vector
    v = Familiar.vector(1, 2, 3, 4)
    w = Familiar.conj v, 5
    assert_equal Familiar.vector(1, 2, 3, 4), v
    assert_equal Familiar.vector(1, 2, 3, 4, 5), w
  end

  # atom.rb
  def test_atom_creates_an_atom
    a = Familiar.atom(3)
    assert a.is_a? Java::clojure.lang.Atom
    assert_equal 3, a.deref
  end

  def test_can_swap_the_value_of_an_atom
    a = Familiar.atom("hello")
    result = a.swap! {|v| v + " world" }
    assert_equal "hello world", result
    assert_equal "hello world", a.deref
  end

  def test_can_reset_the_value_of_an_atom
    a = Familiar.atom([1, 3, 4])
    result = a.reset! "hi"
    assert_equal "hi", result
    assert_equal "hi", a.deref
  end

  def test_atom?
    assert Familiar.atom?(Familiar.atom("hi"))
  end

###############################################

  def test_ref_creates_a_ref
    r = Familiar.ref(Familiar.vector 1, 2, 3, 4)
    assert r.is_a? Java::clojure.lang.Ref
    assert_equal Familiar.vector(1, 2, 3, 4), r.deref
  end

  def test_can_set_a_refs_value
    r = Familiar.ref(6)
    Familiar.dosync do
      r.set 7
    end
    assert_equal 7, r.deref
  end

  def test_can_alter_a_refs_value
    r = Familiar.ref(10)
    Familiar.dosync do
      r.alter {|v| v * 2}
    end
    assert_equal 20, r.deref
  end

  def test_can_commute_a_refs_value
    r = Familiar.ref(11)
    Familiar.dosync do
      r.commute {|v| v * 3}
    end
    assert_equal 33, r.deref
  end

end

