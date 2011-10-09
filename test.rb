require 'rubygems'
require 'familiar'

clj = Familiar
clj.fn(lambda {|x,y| puts "HERE!!! #{x + y}"}).invoke(5, 6)
f = clj.fn(lambda {|x| x + 1 })
a = clj.atom(0)
a.swap(f)
a.swap! do |v|
  v + 1
end

(1..10).each do |i|
  clj.future do
    (1..1000).each do |j|
      a.reset!(a.deref + 1)
      a.swap! do |v|
        v + 1
      end
      a.swap(f)
    end
    puts "#{i} done!"
  end
end
Java::java.lang.Thread.sleep 1000
clj.print a

y = clj.ref("This is a value")
clj.dosync do
  puts "HERE I AM IN DOSYNC"
  y.set "A new value"
end
clj.print y

