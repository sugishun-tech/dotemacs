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
 
;; Pythonの設定
(defun my/python-format-code ()
  "Run autopep8 ignoring the line length rule and applying isort."
  (interactive)
  (when (and (eq major-mode 'python-mode)
             (executable-find "autopep8")
             (executable-find "isort"))
    (shell-command-on-region
     (point-min) (point-max)
     "autopep8 --ignore=E501 - | isort -" nil t)
    (message "autopep8 (ignoring line length) and isort applied.")))
 
(with-eval-after-load 'python
  (define-key python-mode-map (kbd "C-c C-r") 'my/python-format-code))
 
;; Web開発の設定
(require 'web-mode)
(add-to-list 'auto-mode-alist '("\\.html?\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.css\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.js\\'" . web-mode))
 
(defun my/web-mode-hook ()
  "Web modeのフック関数"
  (setq web-mode-markup-indent-offset 2
        web-mode-css-indent-offset 2
        web-mode-code-indent-offset 2))
 
(add-hook 'web-mode-hook 'my/web-mode-hook)
 
;; Emmet-modeの設定
(require 'emmet-mode)
(add-hook 'web-mode-hook 'emmet-mode)
 
;; Cythonの設定
(add-to-list 'auto-mode-alist '("\\.pyx\\'" . cython-mode))
 
;; テーマの設定
(load-theme 'cyberpunk t)
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages
   '(web-mode emmet-mode cython-mode cyberpunk-theme)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
