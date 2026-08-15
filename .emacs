;;; ~/.emacs --- Development settings -*- lexical-binding: t; -*-

;;; Package management

(require 'package)

;; Keep the built-in GNU ELPA archive and add NonGNU ELPA and MELPA.
(add-to-list 'package-archives
             '("nongnu" . "https://elpa.nongnu.org/nongnu/") t)
(add-to-list 'package-archives
             '("melpa" . "https://melpa.org/packages/") t)

(package-initialize)

(defconst my/required-packages
  '(web-mode
    js2-mode
    typescript-mode
    php-mode
    cython-mode
    jinja2-mode
    cyberpunk-theme)
  "Packages required by this configuration.")

;; Install only missing packages.  A network failure must not prevent Emacs
;; from starting; the failed package is simply reported in *Messages*.
(let (missing-packages)
  (dolist (pkg my/required-packages)
    (unless (package-installed-p pkg)
      (push pkg missing-packages)))

  (when missing-packages
    (condition-case err
        (package-refresh-contents)
      (error
       (message "Package archive refresh failed: %s"
                (error-message-string err))))

    (dolist (pkg (nreverse missing-packages))
      (unless (package-installed-p pkg)
        (condition-case err
            (package-install pkg)
          (error
           (message "Package installation failed (%s): %s"
                    pkg (error-message-string err))))))))

;;; Cyberpunk theme

(when (package-installed-p 'cyberpunk-theme)
  (condition-case err
      (progn
        ;; A theme is global, so this applies to every major mode.
        (mapc #'disable-theme custom-enabled-themes)
        (load-theme 'cyberpunk t))
    (error
     (message "Could not load cyberpunk theme: %s"
              (error-message-string err)))))

;;; Python and Cython

(defun my/call-formatter (program arguments file log-buffer)
  "Run PROGRAM with ARGUMENTS on FILE, writing output to LOG-BUFFER.
Signal an error when the process does not exit successfully."
  (let ((exit-code
         (apply #'call-process
                program nil log-buffer nil
                (append arguments (list file)))))
    (unless (and (integerp exit-code) (zerop exit-code))
      (error "%s failed with exit code %s; see %s"
             program exit-code (buffer-name log-buffer)))))

(defun my/replace-buffer-from-file (file)
  "Replace the current buffer contents with FILE."
  (let ((formatted-buffer (generate-new-buffer " *python-formatted*")))
    (unwind-protect
        (progn
          (with-current-buffer formatted-buffer
            (insert-file-contents file))
          (if (fboundp 'replace-buffer-contents)
              (replace-buffer-contents formatted-buffer)
            ;; Compatibility fallback for older Emacs versions.
            (let ((old-point (point)))
              (erase-buffer)
              (insert-file-contents file)
              (goto-char (min old-point (point-max))))))
      (kill-buffer formatted-buffer))))

(defun my/python-format-buffer ()
  "Format the entire Python/Cython buffer with isort and autopep8.

Each formatter is used only when its executable is present in `exec-path'.
The autopep8 E501 rule is ignored, so autopep8 does not enforce the
79-character line-length limit.  Changes are applied only after every
available formatter exits successfully."
  (interactive)
  (let ((isort-program (executable-find "isort"))
        (autopep8-program (executable-find "autopep8")))
    ;; Missing commands are deliberately ignored.
    (when (or isort-program autopep8-program)
      (save-restriction
        (widen)
        (let* ((source-directory
                (and buffer-file-name
                     (file-name-directory buffer-file-name)))
               (temporary-file-directory
                (if (and source-directory
                         (file-writable-p source-directory))
                    source-directory
                  temporary-file-directory))
               (suffix (if (derived-mode-p 'cython-mode) ".pyx" ".py"))
               (temp-file
                (make-temp-file "emacs-python-format-" nil suffix))
               (log-buffer (get-buffer-create "*Python formatter*"))
               (coding-system-for-write buffer-file-coding-system)
               (coding-system-for-read buffer-file-coding-system))
          (unwind-protect
              (progn
                (with-current-buffer log-buffer
                  (erase-buffer))

                (write-region (point-min) (point-max)
                              temp-file nil 'silent)

                ;; Import sorting first, then PEP 8 whitespace cleanup.
                (when isort-program
                  (my/call-formatter
                   isort-program '("--quiet") temp-file log-buffer))

                (when autopep8-program
                  (my/call-formatter
                   autopep8-program
                   '("--in-place" "--ignore=E501")
                   temp-file log-buffer))

                (my/replace-buffer-from-file temp-file)
                (message "Python formatting completed"))
            (when (file-exists-p temp-file)
              (delete-file temp-file))))))))

(defun my/python-editing-setup ()
  "Common setup for Python and Cython buffers."
  (setq-local indent-tabs-mode nil)
  (when (boundp 'python-indent-offset)
    (setq-local python-indent-offset 4))
  (local-set-key (kbd "C-c C-r") #'my/python-format-buffer))

(add-hook 'python-mode-hook #'my/python-editing-setup)
(add-hook 'python-ts-mode-hook #'my/python-editing-setup)
(add-hook 'cython-mode-hook #'my/python-editing-setup)

(autoload 'cython-mode "cython-mode" "Major mode for Cython." t)
(add-to-list 'auto-mode-alist '("\\.pyx\\'" . cython-mode))
(add-to-list 'auto-mode-alist '("\\.pxd\\'" . cython-mode))
(add-to-list 'auto-mode-alist '("\\.pxi\\'" . cython-mode))

;;; Web development modes

(autoload 'web-mode "web-mode" "Major mode for web templates." t)
(autoload 'js2-mode "js2-mode" "Major mode for JavaScript." t)
(autoload 'typescript-mode "typescript-mode" "Major mode for TypeScript." t)
(autoload 'php-mode "php-mode" "Major mode for PHP." t)
(autoload 'jinja2-mode "jinja2-mode" "Major mode for Jinja2 templates." t)

;; Add the generic PHP rule first.  More specific *.blade.php and template
;; rules are prepended afterwards and therefore take priority.
(add-to-list 'auto-mode-alist '("\\.php\\'" . php-mode))
(add-to-list 'auto-mode-alist '("\\.phtml\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.tpl\\.php\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.blade\\.php\\'" . web-mode))

(add-to-list 'auto-mode-alist '("\\.html?\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.xhtml\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.shtml\\'" . web-mode))

(add-to-list 'auto-mode-alist '("\\.css\\'" . css-mode))
(add-to-list 'auto-mode-alist '("\\.scss\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.less\\'" . web-mode))

(add-to-list 'auto-mode-alist '("\\.js\\'" . js2-mode))
(add-to-list 'auto-mode-alist '("\\.mjs\\'" . js2-mode))
(add-to-list 'auto-mode-alist '("\\.cjs\\'" . js2-mode))
(add-to-list 'auto-mode-alist '("\\.ts\\'" . typescript-mode))

;; React: web-mode handles JSX and TSX.
(add-to-list 'auto-mode-alist '("\\.jsx\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.tsx\\'" . web-mode))

;; Other common web-template/component files supported by web-mode.
(add-to-list 'auto-mode-alist '("\\.vue\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.svelte\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.twig\\'" . web-mode))

;; Explicit Jinja2 suffixes.  Files such as page.html.j2 are also covered.
(add-to-list 'auto-mode-alist '("\\.j2\\'" . jinja2-mode))
(add-to-list 'auto-mode-alist '("\\.jinja\\'" . jinja2-mode))
(add-to-list 'auto-mode-alist '("\\.jinja2\\'" . jinja2-mode))

(with-eval-after-load 'web-mode
  (add-to-list 'web-mode-engines-alist
               '("blade" . "\\.blade\\.php\\'"))
  (add-to-list 'web-mode-content-types-alist
               '("jsx" . "\\.\\(jsx\\|tsx\\)\\'")))

(defun my/insert-two-spaces ()
  "Insert exactly two spaces."
  (interactive)
  (insert "  "))

(defun my/web-editing-setup ()
  "Disable automatic indentation and make TAB insert two spaces."
  (setq-local indent-tabs-mode nil)
  (setq-local tab-width 2)
  (setq-local standard-indent 2)
  (setq-local electric-indent-chars nil)

  ;; web-mode also has its own auto-indent-on-yank switch, independent of
  ;; Emacs electric indentation.
  (when (boundp 'web-mode-enable-auto-indentation)
    (setq-local web-mode-enable-auto-indentation nil))

  ;; Keep any manually invoked indentation command at two spaces, even though
  ;; TAB itself is deliberately changed into literal space insertion.
  (dolist (variable
           '(sgml-basic-offset
             css-indent-offset
             js-indent-level
             js2-basic-offset
             typescript-indent-level
             c-basic-offset
             web-mode-markup-indent-offset
             web-mode-css-indent-offset
             web-mode-code-indent-offset
             web-mode-attr-indent-offset))
    (when (boundp variable)
      (set (make-local-variable variable) 2)))

  (when (fboundp 'electric-indent-local-mode)
    (electric-indent-local-mode -1))
  (when (fboundp 'electric-layout-local-mode)
    (electric-layout-local-mode -1))

  ;; php-mode is based on CC Mode, which has another independent electric
  ;; indentation mechanism for characters such as ; and }.
  (when (derived-mode-p 'php-mode)
    (when (fboundp 'c-toggle-auto-newline)
      (c-toggle-auto-newline -1))
    (when (fboundp 'c-toggle-electric-state)
      (c-toggle-electric-state -1)))

  ;; Prevent mode-specific RET commands from indenting the next line.
  (local-set-key (kbd "RET") #'newline)
  (local-set-key (kbd "<return>") #'newline)

  ;; TAB must insert two literal spaces, not run an indentation command.
  (local-set-key (kbd "TAB") #'my/insert-two-spaces)
  (local-set-key (kbd "<tab>") #'my/insert-two-spaces))

(dolist (hook
         '(web-mode-hook
           html-mode-hook
           mhtml-mode-hook
           css-mode-hook
           css-ts-mode-hook
           js-mode-hook
           js2-mode-hook
           js-ts-mode-hook
           typescript-mode-hook
           typescript-ts-mode-hook
           tsx-ts-mode-hook
           php-mode-hook
           jinja2-mode-hook))
  (add-hook hook #'my/web-editing-setup))

;;; .emacs ends here
