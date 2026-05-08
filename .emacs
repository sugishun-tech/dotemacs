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
;; 3. 汎用：シンプルなTab挙動を設定する関数
;; ==========================================
(defun my/apply-simple-tab-settings (mode-key)
  "自動インデントを無効化し、Tabキーを単純なタブストップ移動にする"
  (let ((indent (my/get-conf mode-key "indent" 2))
        (use-tabs (my/get-conf mode-key "use_tabs" nil)))
    
    ;; 自動インデント関数を無効化（単なる改行や挿入にする）
    (setq-local indent-line-function 'indent-to-left-margin)
    
    ;; 基本の幅設定
    (setq-local tab-width indent)
    (setq-local indent-tabs-mode use-tabs)
    
    ;; Tabキーの挙動を「次のタブストップへ移動」に固定
    (local-set-key (kbd "TAB") 'tab-to-tab-stop)
    ;; 0, 4, 8, 12... のようなタブストップリストを作成
    (setq-local tab-stop-list (number-sequence 0 120 indent))
    
    ;; 各モード固有のインデント変数も一応合わせておく
    (setq-local web-mode-markup-indent-offset indent)
    (setq-local web-mode-code-indent-offset indent)
    (setq-local web-mode-css-indent-offset indent)
    (setq-local typescript-indent-level indent)
    (setq-local js-indent-level indent)
    
    (message "%s: Simple Tab applied (width: %d)" mode-key indent)))

;; ==========================================
;; 4. 各モードへの適用（Hook）
;; ==========================================

;; Web Mode (HTML, TSX, JSX, CSS, JS)
(add-hook 'web-mode-hook
          (lambda ()
            (let* ((ext (file-name-extension (or buffer-file-name "")))
                   (mode-key (if (member ext '("tsx" "jsx" "ts" "js")) "typescript" "web")))
              (setq-local web-mode-enable-auto-indentation nil)
              (my/apply-simple-tab-settings mode-key)
              (when (member ext '("tsx" "jsx"))
                (web-mode-set-content-type "jsx")))))

;; TypeScript Mode
(add-hook 'typescript-mode-hook
          (lambda () (my/apply-simple-tab-settings "typescript")))

;; JSON Mode
(add-hook 'json-mode-hook
          (lambda () (my/apply-simple-tab-settings "json")))

;; Python (ここだけはフォーマッタを残す)
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
;; 5. ファイル割り当て & 共通設定
;; ==========================================
(add-to-list 'auto-mode-alist '("\\.tsx\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.jsx\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.html?\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.json\\'" . json-mode))
(add-to-list 'auto-mode-alist '("\\.ts\\'" . typescript-mode))

(setq web-mode-enable-auto-pairing t)
(require 'emmet-mode)
(add-hook 'web-mode-hook 'emmet-mode)

(load-theme 'cyberpunk t)
