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
;; 3. Python / Cython (ここは元のフォーマッタを完コピ)
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
    (setq python-indent-offset indent
          indent-tabs-mode use-tabs
          tab-width indent)))

(add-hook 'python-mode-hook 'my/python-style-hook)
(add-hook 'cython-mode-hook 'my/python-style-hook)
(with-eval-after-load 'python
  (define-key python-mode-map (kbd "C-c C-r") 'my/python-format-code))

;; ==========================================
;; 4. Web / TS / JSON / HTML (Tabをesettingsに固定)
;; ==========================================
(defun my/apply-simple-tab-settings (mode-key)
  "自動計算を殺して、Tabをesettingsの幅分だけ動くようにする"
  (let ((indent (my/get-conf mode-key "indent" 2))
        (use-tabs (my/get-conf mode-key "use_tabs" nil)))
    ;; 自動インデントを無効化
    (setq-local indent-line-function 'indent-to-left-margin)
    (setq-local tab-width indent)
    (setq-local indent-tabs-mode use-tabs)
    ;; Tabキーを「次のタブストップへ移動」に強制上書き
    (local-set-key (kbd "TAB") 'tab-to-tab-stop)
    (setq-local tab-stop-list (number-sequence 0 120 indent))
    ;; 各モードの内部変数も念のため同期
    (setq-local web-mode-markup-indent-offset indent)
    (setq-local web-mode-code-indent-offset indent)
    (setq-local web-mode-css-indent-offset indent)
    (setq-local typescript-indent-level indent)
    (setq-local js-indent-level indent)
    (message "%s: Simple Tab applied (width: %d)" mode-key indent)))

;; Web-mode (HTML, TSX, JSX, CSS, JS)
(add-hook 'web-mode-hook
  (lambda ()
    (let* ((ext (file-name-extension (or buffer-file-name "")))
            (mode-key (if (member ext '("tsx" "jsx" "ts" "js")) "typescript" "web")))
      (setq-local web-mode-enable-auto-indentation nil) ; web-modeのお節介をオフ
      (my/apply-simple-tab-settings mode-key)
      (when (member ext '("tsx" "jsx"))
        (web-mode-set-content-type "jsx")))))

;; TypeScript / JSON 
(add-hook 'typescript-mode-hook (lambda () (my/apply-simple-tab-settings "typescript")))
(add-hook 'json-mode-hook (lambda () (my/apply-simple-tab-settings "json")))

;; ==========================================
;; 5. ファイル割り当て & 共通
;; ==========================================
(add-to-list 'auto-mode-alist '("\\.tsx\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.jsx\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.html?\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.json\\'" . json-mode))
(add-to-list 'auto-mode-alist '("\\.ts\\'" . typescript-mode))
(add-to-list 'auto-mode-alist '("\\.pyx\\'" . cython-mode))

(setq web-mode-enable-auto-pairing t)
(require 'emmet-mode)
(add-hook 'web-mode-hook 'emmet-mode)
(load-theme 'cyberpunk t)
