namespace Notes.Util {
    //  public class Debouncer<A> {
    //      public delegate void DebounceCallback<A>(A arg);

    //      private int timeout;
    //      private uint timeout_source = -1;
    //      private DebounceCallback<A> callback;

    //      public Debouncer(int timeout, DebounceCallback<A> callback) {
    //          this.timeout = timeout;
    //          this.callback = callback;
    //      }

    //      private void invoke_callback(A arg) {
    //          timeout_source = -1;
    //          this.callback(arg);
    //      }

    //      public void call<A>(A arg) {
    //          if (timeout_source > -1)
    //              Source.remove(timeout_source);

    //          timeout_source = Timeout.add_full(Priority.DEFAULT, timeout, () => {
    //              invoke_callback(arg);
    //              return false;
    //          });
    //      }
    //  }
}