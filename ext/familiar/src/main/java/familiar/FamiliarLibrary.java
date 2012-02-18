package familiar;

import clojure.lang.IFn;
import clojure.lang.IPersistentCollection;
import clojure.lang.IPersistentVector;
import clojure.lang.ISeq;
import clojure.lang.LockingTransaction;
import clojure.lang.PersistentVector;
import org.jruby.NativeException;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyException;
import org.jruby.RubyModule;
import org.jruby.RubyObject;
import org.jruby.anno.JRubyMethod;
import org.jruby.exceptions.RaiseException;
import org.jruby.runtime.Block;
import org.jruby.runtime.ObjectAllocator;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.runtime.load.Library;

import java.io.IOException;
import java.util.concurrent.Callable;

public class FamiliarLibrary implements Library {
    private Ruby runtime;
    private RubyClass vectorClass;

    public void load(Ruby ruby, boolean wrap) throws IOException {
        runtime = ruby;

        RubyModule familiar = ruby.defineModule("Familiar");

        RubyModule ext = familiar.defineModuleUnder("Ext");
        ext.defineAnnotatedMethods(Ext.class);
    }

    public static class Ext {
        @JRubyMethod(module = true)
        public static IRubyObject dosync(final ThreadContext context, final IRubyObject self, final Block block) throws Exception {
            final Ruby ruby = context.runtime;

            return (IRubyObject) LockingTransaction.runInTransaction(new Callable() {
                public Object call() throws Exception {
                    // re-get transaction in case this gets run in different threads
                    try {
                        final IRubyObject result = block.call(ruby.getCurrentContext());
                        return result;
                    } catch (RaiseException e) {
                        final RubyException rubyException = e.getException();
                        if(rubyException instanceof NativeException) {
                            final NativeException ne = (NativeException) rubyException;
                            final Throwable cause = (Throwable) ne.getCause();
                            if(cause != null &&
                                "clojure.lang.LockingTransaction$RetryEx".equals(cause.getClass().getName())) {
                                throw (Error) cause;
                            }
                            else {
                                throw e;
                            }
                        }
                        else {
                            throw e;
                        }
                    }
                }
            });
        }
    }
}
