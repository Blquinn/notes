namespace Notes.Util {
    public class Debouncer {
        public signal void callback();

        private uint timeout;
        private uint? timeout_source = null;

        public Debouncer(uint timeout) {
            this.timeout = timeout;
        }

        ~Debouncer() {
            remove_timeout();
        }

        private void invoke_callback() {
            timeout_source = null;
            callback();
        }

        private void remove_timeout() {
            if (timeout_source != null)
                Source.remove(timeout_source);
        }

        public void call() {
            remove_timeout();

            timeout_source = Timeout.add_full(Priority.DEFAULT, timeout, () => {
                invoke_callback();
                return false;
            });
        }
    }
}