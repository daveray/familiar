module Familiar

  def self.seq(coll)
    Java::clojure.lang.RT.seq(coll)
  end
  def self.first(coll)
    Java::clojure.lang.RT.first(coll)
  end
  def self.rest(coll)
    Java::clojure.lang.RT.more(coll)
  end
  def self.next(coll)
    Java::clojure.lang.RT.next(coll)
  end

end
