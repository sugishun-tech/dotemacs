;; ==========================================
;; 1. パッケージ管理システム
;; ==========================================
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

(defvar my/packages '(cyberpunk-theme web-mode emmet-mode cython-mode json-mode typescript-mode))
(unless package-archive-contents (package-refresh-contents))
(dolist (pkg my/packages) (unless (package-installed-p pkg) (package-install pkg)))

;; ==========================================
;; 2. JSON設定の読み込み
;; ==========================================
(require 'json)
(defvar my/esettings nil)

(defun my/load-esettings ()
  "`.emacs` 本体と同じディレクトリにある `.esettings.json` を確実に探す"
  (let* ((base-dir (file-name-directory (file-truename (or user-init-file "~/.emacs"))))
         (settings-file (expand-file-name ".esettings.json" base-dir)))
    (if (file-exists-p settings-file)
        (let ((json-object-type 'alist))
          (setq my/esettings (json-read-file settings-file))
          (message "Settings loaded from: %s" settings-file))
      (message "Warning: .esettings.json not found in %s" base-dir))))

(my/load-esettings)

(defun my/get-conf (mode key default)
  (let* ((mode-conf (assoc mode my/esettings))
         (val (assoc key (cdr mode-conf))))
    (if val (cdr val) default)))

;; ==========================================
;; 3. Python (フォーマッタ維持)
;; ==========================================
(defun my/python-format-code ()
  (interactive)
  (let* ((indent (my/get-conf "python" "indent" 4))
         (cmd (format "autopep8 --indent-size=%d - | isort -" indent)))
    (shell-command-on-region (point-min) (point-max) cmd nil t)))

(add-hook 'python-mode-hook
          (lambda ()
            (let ((indent (my/get-conf "python" "indent" 4)))
              (setq python-indent-offset indent
                    indent-tabs-mode (my/get-conf "python" "use_tabs" nil)
                    tab-width indent))
            (local-set-key (kbd "C-c C-r") 'my/python-format-code)))

;; ==========================================
;; 4. Web Mode / TSX (Tabの自動機能を無効化)
;; ==========================================
(defun my/web-mode-simple-tab-hook ()
  (let* ((ext (file-name-extension (or buffer-file-name "")))
         (mode-key (if (member ext '("tsx" "jsx" "ts" "js")) "typescript" "web"))
         (indent (my/get-conf mode-key "indent" 2))
         (use-tabs (my/get-conf mode-key "use_tabs" nil)))

    ;; web-mode の自動インデント計算を無効化する設定
    (setq-local indent-line-function 'indent-to-left-margin) ; 自動計算をやめる
    (setq-local web-mode-enable-auto-indentation nil)       ; 構文ベースの自動インデントオフ
    (setq-local web-mode-enable-indentation-static t)      ; 静的インデント

    ;; 基本的な幅の設定
    (setq-local tab-width indent)
    (setq-local indent-tabs-name use-tabs)
    (setq-local web-mode-markup-indent-offset indent)
    (setq-local web-mode-code-indent-offset indent)
    (setq-local web-mode-css-indent-offset indent)

    ;; Tabキーの挙動を「単なるインデント挿入」に上書き
    (local-set-key (kbd "TAB") 'tab-to-tab-stop)
    (setq-local tab-stop-list (number-sequence indent 120 indent))

    (when (member ext '("tsx" "jsx"))
      (web-mode-set-content-type "jsx"))
    (message "web-mode: Simple Tab mode (width: %d)" indent)))

(add-hook 'web-mode-hook 'my/web-mode-simple-tab-hook)

;; ==========================================
;; 5. TypeScript / JSON
;; ==========================================
(defun my/simple-indent-setup (mode-name)
  (let ((indent (my/get-conf mode-name "indent" 2)))
    (setq-local tab-width indent)
    (setq-local indent-tabs-mode (my/get-conf mode-name "use_tabs" nil))
    (setq-local typescript-indent-level indent)
    (setq-local js-indent-level indent)))

(add-hook 'typescript-mode-hook (lambda () (my/simple-indent-setup "typescript")))
(add-hook 'json-mode-hook (lambda () (my/simple-indent-setup "json")))

;; ==========================================
;; 6. ファイル割り当て & 共通
;; ==========================================
(add-to-list 'auto-mode-alist '("\\.tsx\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.jsx\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.ts\\'" . typescript-mode))
(add-to-list 'auto-mode-alist '("\\.json\\'" . json-mode))
(add-to-list 'auto-mode-alist '("\\.html?\\'" . web-mode))

(setq web-mode-enable-auto-pairing t)
(require 'emmet-mode)
(add-hook 'web-mode-hook 'emmet-mode)
(load-theme 'cyberpunk t)
