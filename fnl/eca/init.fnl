(local {: autoload} (require :eca.nfnl.module))
(local notify (autoload :eca.nfnl.notify))

(fn setup []
  (notify.info "Hello, World!"))

{: setup}
