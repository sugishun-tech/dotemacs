;; パッケージ管理システムの設定
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)
 
;; インストールするパッケージリスト
(defvar my/packages
  '(cyberpunk-theme
    web-mode
    emmet-mode
    cython-mode))
 
;; パッケージの自動インストール
(unless package-archive-contents
  (package-refresh-contents))
 
(dolist (pkg my/packages)
  (unless (package-installed-p pkg)
    (package-install pkg)))

;; ==========================================
;; JSON設定の読み込み (.esettings.json)
;; ==========================================
(require 'json)

(defvar my/esettings nil)
(defun my/load-esettings ()
  "ユーザーディレクトリから .esettings.json を読み込む"
  ;; .emacsと同じディレクトリのパスを取得
  (let ((settings-file (expand-file-name ".esettings.json" (file-name-directory user-init-file))))
    (if (file-exists-p settings-file)
        (let ((json-object-type 'alist)
              (json-array-type 'list)
              (json-key-type 'string))
          (setq my/esettings (json-read-file settings-file)))
      (setq my/esettings nil))))

;; 起動時に設定をロード
(my/load-esettings)

(defun my/get-setting (key default)
  "JSONから設定値を取得するヘルパー関数"
  (if my/esettings
      (let ((val (assoc key my/esettings)))
        (if val (cdr val) default))
    default))

;; グローバルなタブ/スペース設定
(setq-default indent-tabs-mode (my/get-setting "use_tabs" nil))

;; ==========================================
;; Pythonの設定
;; ==========================================
(defun my/python-format-code ()
  "Run autopep8 and isort, handling tab vs space settings."
  (interactive)
  (when (and (derived-mode-p 'python-mode)
             (executable-find "autopep8")
             (executable-find "isort"))
    (let* ((indent-size (my/get-setting "python_indent_size" 4))
           (use-tabs (my/get-setting "use_tabs" nil))
           ;; Tabを使う場合は、Tab関連のPEP8警告を無視させる
           (ignore-rules (if use-tabs "E501,W191,E101,E111,E114" "E501"))
           (cmd (format "autopep8 --ignore=%s --indent-size=%d - | isort -" ignore-rules indent-size)))
      (shell-command-on-region (point-min) (point-max) cmd nil t)
      (message "autopep8 (ignore: %s) and isort applied." ignore-rules))))

(defun my/python-mode-hook ()
  (let ((use-tabs (my/get-setting "use_tabs" nil))
        (indent-size (my/get-setting "python_indent_size" 4)))
    (setq python-indent-offset indent-size
          indent-tabs-mode use-tabs)
    ;; Tab使用時はEmacsの見た目上のTab幅も合わせる
    (when use-tabs (setq tab-width indent-size))))

(add-hook 'python-mode-hook 'my/python-mode-hook)

(with-eval-after-load 'python
  (define-key python-mode-map (kbd "C-c C-r") 'my/python-format-code))

;; ==========================================
;; Web開発の設定
;; ==========================================
(require 'web-mode)
(add-to-list 'auto-mode-alist '("\\.html?\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.css\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.js\\'" . web-mode))

(defun my/web-mode-hook ()
  "Web modeのフック関数 (JSONから設定を反映)"
  (let ((indent (my/get-setting "web_indent_size" 2))
        (use-tabs (my/get-setting "use_tabs" nil)))
    (setq web-mode-markup-indent-offset indent
          web-mode-css-indent-offset indent
          web-mode-code-indent-offset indent
          indent-tabs-mode use-tabs)
    (when use-tabs (setq tab-width indent))))

(add-hook 'web-mode-hook 'my/web-mode-hook)

(defun my/web-format-code ()
  "Webモード用のオートフォーマット (Emacs標準のインデントを適用)"
  (interactive)
  (indent-region (point-min) (point-max))
  (message "Formatted web buffer based on .esettings.json rules."))

(with-eval-after-load 'web-mode
  (define-key web-mode-map (kbd "C-c C-r") 'my/web-format-code))

;; Emmet-modeの設定
(require 'emmet-mode)
(add-hook 'web-mode-hook 'emmet-mode)

;; ==========================================
;; Cythonの設定
;; ==========================================
(add-to-list 'auto-mode-alist '("\\.pyx\\'" . cython-mode))

(defun my/cython-mode-hook ()
  "Cython modeのフック関数 (JSONから設定を反映)"
  (let ((indent (my/get-setting "cython_indent_size" 4))
        (use-tabs (my/get-setting "use_tabs" nil)))
    (setq python-indent-offset indent
          indent-tabs-mode use-tabs)
    (when use-tabs (setq tab-width indent))))

(defun my/cython-format-code ()
  "Cython用のオートフォーマット"
  (interactive)
  ;; autopep8はCython構文で壊れるため、Emacs標準のインデントを使用
  (indent-region (point-min) (point-max))
  (message "Formatted cython buffer (Using Emacs standard indent)."))

(with-eval-after-load 'cython-mode
  ;; cython-modeはpython-modeを継承している場合があるため独自定義
  (define-key cython-mode-map (kbd "C-c C-r") 'my/cython-format-code))

;; ==========================================
;; テーマ等の設定
;; ==========================================
(load-theme 'cyberpunk t)
(custom-set-variables
 '(package-selected-packages
   '(web-mode emmet-mode cython-mode cyberpunk-theme)))
(custom-set-faces)
