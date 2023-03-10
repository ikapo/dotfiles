;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Font
(setq doom-font (font-spec :family "Mononoki Nerd Font" :size 24))

; Theme
(setq doom-theme 'doom-one)

;; Corrects (and improves) org-mode's native fontification.
(doom-themes-org-config)

;; Set indentations to spaces
(setq-default indent-tabs-mode nil)

; Set treemacs theme
(require 'treemacs-material-icons)
(setq doom-themes-treemacs-theme "material-icons")
(doom-themes-treemacs-config)

; Set relative line numbers
(setq display-line-numbers-type 'relative)

;; Keybindings
(global-set-key (kbd "C-/") 'comment-line)
(global-set-key (kbd "C-f") 'forward-char)
(global-set-key (kbd "C-o") 'forward-line)
(global-set-key (kbd "C-SPC") '+company/complete)
(global-set-key (kbd "C-q") 'evil-quit-all)

; Set key motion shortcuts
(define-key evil-motion-state-map " " nil)
(define-key evil-motion-state-map (kbd "SPC e") 'shell)
(define-key evil-motion-state-map (kbd "SPC d") '+treemacs/toggle)
(define-key evil-motion-state-map (kbd "SPC z") 'ranger)
(setq-default evil-escape-key-sequence "kj")

;; Yassnippet config
(yas-global-mode 1)
(add-hook 'yas-minor-mode-hook (lambda()
                                 (yas-activate-extra-mode 'fundamental-mode)))

;; Remove company-box doc since it breaks yasnippet
(setq company-box-doc-enable nil)
;; aligns annotation to the right hand side
(setq company-tooltip-align-annotations t)

;; LSP config
(setq gc-cons-threshold 100000000)
(use-package lsp-mode
 :hook ((rjsx-mode . lsp)
        (typescript-mode . lsp)
        (typescript-tsx-mode . lsp)
        (web-mode . lsp)
        (json-mode . lsp)
        (js2-mode . lsp))
  :commands lsp
  :defer t
  :config
(setq lsp-idle-delay 0.500
       lsp-enable-file-watchers nil)

 ;; Fix null character error, TODO remove this once on Emacs 29
 (advice-add 'json-parse-string :around
             (lambda (orig string &rest rest)
               (apply orig (s-replace "\\u0000" "" string)
                      rest)))

 (advice-add 'json-parse-buffer :around
             (lambda (oldfn &rest args)
               (save-excursion
                 (while (search-forward "\\u0000" nil t)
                   (replace-match "" nil t)))
        	 (apply oldfn args)))
 )

;; Emacsclient persp mode config
(after! persp-mode
  (setq persp-emacsclient-init-frame-behaviour-override "main"))

;; Astro
(add-to-list 'auto-mode-alist '("\\.astro\\'" . web-mode))

;; MDX
(add-to-list 'auto-mode-alist '("\\.mdx\\'" . markdown-mode))

;; Svelte
(add-to-list 'auto-mode-alist '("\\.svelte\\'" . web-mode))

;; Tailwind
(setq lsp-tailwindcss-add-on-mode t)
(setq lsp-tailwindcss-major-modes '(typescript-tsx-mode tsx-mode web-mode))

;; Prettier
(add-hook 'after-init-hook #'global-prettier-mode)

;; Typescript mode
(setq typescript-indent-level 2
      typescript-expr-indent-offset 2)

;; Typescript LSP
(setq lsp-clients-typescript-max-ts-server-memory 4096)
(setq lsp-clients-typescript-prefer-use-project-ts-server t)
(setq lsp-typescript-suggest-complete-function-calls t)

;; Disable lsp formatting since prettier is used
(setq-hook! 'typescript-mode-hook +format-with-lsp nil)
(setq-hook! 'typescript-tsx-mode-hook +format-with-lsp nil)

;; Copilot config
(use-package! copilot
  :hook (prog-mode . copilot-mode)
  :bind (("C-TAB" . 'copilot-accept-completion-by-word)
         ("C-<tab>" . 'copilot-accept-completion-by-word)
         :map copilot-completion-map
         ("<f19>" . 'copilot-accept-completion)
         ("M-SPC" . 'copilot-accept-completion)
         ("TAB" . 'copilot-accept-completion)))
