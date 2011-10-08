module Familiar

  def self.ref(v)
    Java::clojure.lang.Ref.new v
  end

  def self.dosync(&code)
    Java::clojure.lang.LockingTransaction.runInTransaction(Callable.new(code))
  end


end
