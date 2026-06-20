(progn
  (require 'url)
  (let* ((base "https://raw.githubusercontent.com/chubbyhippo/init.el/refs/heads/main/")
         (dir  (expand-file-name "~/.config/emacs/")))
    (make-directory dir t)
    (dolist (file '("early-init.el" "init.el"))
      (let ((inhibit-message t))
        (url-copy-file (concat base file) (expand-file-name file dir) t))
      (princ (format "Installed %s -> %s\n" file dir)))))
