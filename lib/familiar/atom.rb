module Familiar

  def self.atom(v)
    Java::clojure.lang.Atom.new v
  end

  class Java::ClojureLang::Atom
    def swap!(&code)
      swap(Familiar.fn(code))
    end
    def reset!(v)
      reset(v)
    end
  end

end
