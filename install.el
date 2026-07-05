(progn
  (require 'url)
  (let* ((url-show-status nil)        ; silence url.el's "Contacting host: ..." progress line
         (base "https://raw.githubusercontent.com/chubbyhippo/init.el/refs/heads/main/")
         (dir  (expand-file-name "~/.config/emacs/")))
    (dolist (file '("early-init.el"
                    "init.el"
                    "extras/clojure.el"
                    "extras/cpp.el"
                    "extras/go.el"
                    "extras/haskell.el"
                    "extras/python.el"
                    "extras/rust.el"
                    "extras/typescript.el"
                    "extras/zig.el"))
      (let ((dest (expand-file-name file dir)))
        (make-directory (file-name-directory dest) t)  ; create dir / extras/ as needed
        (let ((inhibit-message t))
          (url-copy-file (concat base file) dest t))
        (message "Installed %s" dest)))))
