;;; zig.el --- Zig development extras  -*- lexical-binding: t; -*-

;; Optional Zig layer for init.el. Disabled by default — uncomment the matching
;; loader at the bottom of init.el to enable it.
;;
;; Zig is the odd one out: it has no built-in Emacs mode, so the major mode comes
;; from zig-mode (NonGNU ELPA, installed like any package here). eglot is built
;; in. You supply the external tools:
;;   - the `zig' CLI — for `zig fmt'-on-save and M-x zig-build / zig-run / zig-test
;;   - zls, the Zig language server — eglot launches it once it's on PATH
;;   - LLVM's lldb-dap — used by the dape config added below (dape ships no Zig
;;     config, so this file registers one)
;;
;; zig-mode formats with `zig fmt' on save out of the box (zig-format-on-save,
;; on by default — set it to nil to disable).
;;
;; ELPA-only: zig-mode is on NonGNU ELPA, dape on GNU ELPA; eglot is built in.

;;; NonGNU ELPA
;; zig-mode auto-binds .zig and derives from prog-mode, so eglot attaches via
;; init.el's prog-mode hook. eglot has no Zig entry, so point it at zls.
(use-package zig-mode
  :ensure t
  :mode "\\.zig\\'")

(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs '(zig-mode . ("zls"))))
;;; End NonGNU ELPA

;;; GNU ELPA
;; DAP-based debugging via dape. It ships no Zig config, so register an lldb-dap
;; one (needs LLVM's lldb-dap). M-x dape → `zig-lldb'; tweak :program to your
;; built binary if it isn't the default. Set breakpoints with
;; `dape-breakpoint-toggle'; n / c step once a session stops.
(use-package dape
  :ensure t
  :commands (dape dape-breakpoint-toggle)
  :custom
  (dape-buffer-window-arrangement 'right)  ; debugger windows on the right
  (dape-inlay-hints t))                     ; show variable values inline when stopped

(with-eval-after-load 'dape
  (add-to-list 'dape-configs
               '(zig-lldb
                 modes (zig-mode)
                 ensure dape-ensure-command
                 command-cwd dape-command-cwd
                 command "lldb-dap"
                 :type "lldb-dap"
                 :request "launch"
                 :cwd "."
                 :program "zig-out/bin/main")))
;;; End GNU ELPA

(provide 'zig)
;;; zig.el ends here
