;; パッケージ管理システムの設定
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

;; インストールするパッケージリスト
(defvar my/packages
  '(cyberpunk-theme
     web-mode
     emmet-mode
     cython-mode
     json-mode)) ;; JSONモードを追加

(unless package-archive-contents (package-refresh-contents))
(dolist (pkg my/packages)
  (unless (package-installed-p pkg) (package-install pkg)))

;; ==========================================
;; JSON設定の読み込みと汎用関数
;; ==========================================
(require 'json)
(defvar my/esettings nil)

(defun my/load-esettings ()
  "JSON設定ファイルを読み込む"
  (let ((settings-file (expand-file-name ".esettings.json" (file-name-directory user-init-file))))
    (if (file-exists-p settings-file)
      (let ((json-object-type 'alist))
        (setq my/esettings (json-read-file settings-file)))
      (setq my/esettings nil))))

(my/load-esettings)

(defun my/get-conf (mode key default)
  "指定したモードのキーに対応する設定値を取得"
  (let* ((mode-conf (assoc mode my/esettings))
          (val (assoc key (cdr mode-conf))))
    (if val (cdr val) default)))

;; ==========================================
;; Python / Cython 設定
;; ==========================================
(defun my/python-format-code ()
  "Run autopep8 and isort."
  (interactive)
  (when (and (derived-mode-p 'python-mode) (executable-find "autopep8") (executable-find "isort"))
    (let* ((indent (my/get-conf "python" "indent" 4))
            (use-tabs (my/get-conf "python" "use_tabs" nil))
            (ignore (if use-tabs "E501,W191,E101,E111,E114" "E501"))
            (cmd (format "autopep8 --ignore=%s --indent-size=%d - | isort -" ignore indent)))
      (shell-command-on-region (point-min) (point-max) cmd nil t)
      (message "Python formatted."))))

(defun my/python-style-hook ()
  (let ((indent (my/get-conf "python" "indent" 4))
         (use-tabs (my/get-conf "python" "use_tabs" nil)))
    (setq python-indent-offset indent indent-tabs-mode use-tabs)
    (if use-tabs (setq tab-width indent))))
(add-hook 'python-mode-hook 'my/python-style-hook)

(defun my/cython-style-hook ()
  (let ((indent (my/get-conf "cython" "indent" 4))
         (use-tabs (my/get-conf "cython" "use_tabs" nil)))
    (setq python-indent-offset indent indent-tabs-mode use-tabs)
    (if use-tabs (setq tab-width indent))))
(add-hook 'cython-mode-hook 'my/cython-style-hook)

(defun my/format-by-indent-region ()
  (interactive)
  (indent-region (point-min) (point-max))
  (message "Formatted by indent-region."))

(with-eval-after-load 'python (define-key python-mode-map (kbd "C-c C-r") 'my/python-format-code))
(with-eval-after-load 'cython-mode (define-key cython-mode-map (kbd "C-c C-r") 'my/format-by-indent-region))

;; ==========================================
;; Web Mode 設定
;; ==========================================
(defun my/web-mode-hook ()
  (let ((indent (my/get-conf "web" "indent" 2))
         (use-tabs (my/get-conf "web" "use_tabs" nil)))
    (setq web-mode-markup-indent-offset indent
      web-mode-css-indent-offset indent
      web-mode-code-indent-offset indent
      indent-tabs-mode use-tabs)
    (if use-tabs (setq tab-width indent))))
(add-hook 'web-mode-hook 'my/web-mode-hook)
(with-eval-after-load 'web-mode (define-key web-mode-map (kbd "C-c C-r") 'my/format-by-indent-region))

;; ==========================================
;; Lisp (Emacs Lisp) 設定
;; ==========================================
(defun my/lisp-mode-hook ()
  (let ((indent (my/get-conf "lisp" "indent" 2))
         (use-tabs (my/get-conf "lisp" "use_tabs" nil)))
    (setq lisp-indent-offset indent
      indent-tabs-mode use-tabs)
    (if use-tabs (setq tab-width indent))))

(add-hook 'emacs-lisp-mode-hook 'my/lisp-mode-hook)
(with-eval-after-load 'elisp-mode (define-key emacs-lisp-mode-map (kbd "C-c C-r") 'my/format-by-indent-region))

;; ==========================================
;; JSON 設定 (多行フォーマット対応)
;; ==========================================
(defun my/json-format-code ()
  "MinifyされたJSONも多行に展開してフォーマットする"
  (interactive)
  (let ((indent (my/get-conf "json" "indent" 2))
         (use-tabs (my/get-conf "json" "use_tabs" nil)))
    ;; json-pretty-printは現在のjs-indent-levelやtab-widthを参照する
    (setq js-indent-level indent
      indent-tabs-mode use-tabs)
    (if use-tabs (setq tab-width indent))
    (json-pretty-print-buffer)
    (message "JSON formatted and expanded.")))

(defun my/json-mode-hook ()
  (let ((indent (my/get-conf "json" "indent" 2))
         (use-tabs (my/get-conf "json" "use_tabs" nil)))
    (setq js-indent-level indent
      indent-tabs-mode use-tabs)
    (if use-tabs (setq tab-width indent))))

(add-hook 'json-mode-hook 'my/json-mode-hook)
(with-eval-after-load 'json-mode (define-key json-mode-map (kbd "C-c C-r") 'my/json-format-code))

;; ==========================================
;; その他共通設定
;; ==========================================
(require 'emmet-mode)
(add-hook 'web-mode-hook 'emmet-mode)
(add-to-list 'auto-mode-alist '("\\.html?\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.css\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.js\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.pyx\\'" . cython-mode))

(load-theme 'cyberpunk t)
