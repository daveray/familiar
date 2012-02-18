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

  def test_gets_illegal_state_exception_when_modifying_ref_outside_dosync
    r = Familiar.ref(6)
    begin
      r.set 7
      fail "Expected java.lang.IllegalStateException"
    rescue java.lang.IllegalStateException
    end
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

  def test_can_convert_a_ruby_vector_to_clojure
    ruby = [1, 2, 3, 4]
    clojure = ruby.to_clojure
    assert Familiar.vector?(clojure)
    assert_equal Familiar.vector(1, 2, 3, 4), clojure
  end

  def test_can_convert_a_ruby_hash_to_clojure
    ruby = {"a" => "b", "c" => 99}
    clojure = ruby.to_clojure
    assert Familiar.map?(clojure)
    assert_equal Familiar.hash_map("a", "b", "c", 99), clojure
  end

  def test_can_convert_a_ruby_symbol_to_clojure_keyword
    clojure = :hello.to_clojure
    assert Familiar.keyword?(clojure)
    assert_equal Familiar.keyword("hello"), clojure
  end

  def test_can_convert_a_ruby_set_to_clojure_set
    clojure = Set.new([1, 2, 3, 4]).to_clojure
    assert Familiar.set?(clojure)
    assert_equal Familiar.hash_set(1, 2, 3, 4), clojure
  end

  def test_recursively_converts_ruby_object_to_clojure
    f = Familiar
    clojure = [[1, 2, 3], {"hi" => "bye", :foo => [4, 5, 6]}].to_clojure
    assert f.vector?(clojure)
    # TODO it's not clear why Ruby's == is returning nil instead of true
    # or false here.
    #assert_equal f.vector(f.vector(1, 2, 3), f.hash_map("hi", "bye")), clojure
    assert f.vector(f.vector(1, 2, 3), 
                    f.hash_map("hi", "bye",
                               f.keyword("foo"), f.vector(4, 5, 6))).equals(clojure)
  end

  def test_can_convert_a_clojure_keyword_to_ruby_symbol
    rb = Familiar.keyword("hello").to_ruby
    assert rb.class == Symbol
    assert_equal :hello, rb
  end

  def test_can_convert_a_clojure_vector_to_ruby_array
    rb = Familiar.vector(5, 6, 7).to_ruby
    assert rb.class == Array
    assert_equal [5, 6, 7], rb
  end

  def test_can_convert_a_clojure_list_to_ruby_array
    rb = Familiar.list(5, 6, 7).to_ruby
    assert rb.class == Array
    assert_equal [5, 6, 7], rb
  end

  def test_can_convert_a_clojure_seq_to_ruby_array
    rb = Familiar.range(5).to_ruby
    assert rb.class == Array
    assert_equal [0, 1, 2, 3, 4], rb
  end

  def test_can_convert_a_clojure_array_map_to_ruby_hash
    rb = Familiar.array_map("hi", "bye", "yum", "bar").to_ruby
    assert rb.class == Hash
    assert_equal({"hi" => "bye", "yum" => "bar" }, rb)
  end

  def test_can_convert_a_clojure_hash_map_to_ruby_hash
    rb = Familiar.hash_map("hi", "bye", "yum", "bar").to_ruby
    assert rb.class == Hash
    assert_equal({"hi" => "bye", "yum" => "bar" }, rb)
                 
  end

  def test_can_convert_a_clojure_hash_set_to_ruby_set
    rb = Familiar.hash_set("a", 4, 1).to_ruby
    assert rb.class == Set
    assert_equal Set.new(["a", 1, 4]), rb
  end

  def test_can_convert_nested_clojure_objects_to_ruby
    rb = Familiar.with do
      hash_map(keyword("foo"), "bar",
               "yum", vector(:yum, 2, 3),
               99, hash_set("a", "b", keyword("c")))
    end.to_ruby

    assert rb.class == Hash
    assert_equal({:foo  => "bar",
                  "yum" => [:yum, 2, 3],
                  99    => Set.new(["a", "b", :c])}, rb)
  end

end

