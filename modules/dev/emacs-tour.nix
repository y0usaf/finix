{
  config,
  lib,
  pkgs,
  ...
}: let
  emacsWithPkgs = pkgs.emacs-pgtk.pkgs.withPackages (epkgs:
    with epkgs; [
      vertico
      marginalia
      orderless
      consult
      magit
      org-modern
      org-auto-tangle
      olivetti
      nix-mode
      rainbow-delimiters
    ]);
in {
  options.user.dev.emacs-tour = {
    enable = lib.mkEnableOption "Emacs with a guided why-Emacs-is-great tour";
  };
  config = lib.mkIf config.user.dev.emacs-tour.enable {
    environment.systemPackages = [
      emacsWithPkgs
    ];
    manzil.users."${config.user.name}".files = {
      ".config/emacs/init.el".text = ''
        ;;; init.el --- the Emacs tour -*- lexical-binding: t; -*-

        ;; Quiet, pretty defaults
        (setq inhibit-startup-screen t
              ring-bell-function 'ignore
              use-short-answers t
              make-backup-files nil
              custom-file (expand-file-name "emacs-custom.el" "~/.cache/"))
        (menu-bar-mode -1)
        (tool-bar-mode -1)
        (scroll-bar-mode -1)
        (load-theme 'modus-vivendi-tinted t)
        (pixel-scroll-precision-mode 1)

        ;; Modern minibuffer: fuzzy matching + annotations + live preview
        (vertico-mode 1)
        (marginalia-mode 1)
        (setq completion-styles '(orderless basic)
              completion-category-defaults nil)
        (which-key-mode 1)
        (global-set-key (kbd "C-s") #'consult-line)
        (global-set-key (kbd "C-x b") #'consult-buffer)
        (global-set-key (kbd "M-y") #'consult-yank-pop)

        ;; Org: the star of the show
        (with-eval-after-load 'org
          (setq org-confirm-babel-evaluate nil
                org-hide-emphasis-markers t
                org-ellipsis "  ⤵")
          (org-babel-do-load-languages
           'org-babel-load-languages
           '((emacs-lisp . t) (shell . t))))
        ;; ~/nixos as an org project: capture from anywhere, agenda as dashboard
        (setq org-directory "~/nixos"
              org-default-notes-file "~/nixos/TODO.org"
              org-agenda-files '("~/nixos/TODO.org")
              org-log-done 'time
              org-capture-templates
              '(("t" "Nix task" entry (file+headline "~/nixos/TODO.org" "Tasks")
                 "* TODO %?\n%U")
                ("i" "Idea" entry (file+headline "~/nixos/TODO.org" "Ideas")
                 "* %?\n%U")
                ("p" "Package to try" checkitem
                 (file+headline "~/nixos/TODO.org" "Packages to try")
                 "- [ ] %?")))
        (global-set-key (kbd "C-c c") #'org-capture)
        (global-set-key (kbd "C-c a") #'org-agenda)

        ;; The whole system config as one literate document: nixos.org is
        ;; the editing surface; saving it tangles the .nix files back out.
        (add-hook 'org-mode-hook #'org-auto-tangle-mode)
        (global-set-key (kbd "C-c n")
                        (lambda () (interactive) (find-file "~/nixos/nixos.org")))

        (add-hook 'org-mode-hook #'org-modern-mode)
        (add-hook 'org-mode-hook #'olivetti-mode)
        (add-hook 'org-mode-hook #'visual-line-mode)
        (add-hook 'prog-mode-hook #'rainbow-delimiters-mode)

        ;; Open a writable copy of the tour on startup
        (add-hook 'emacs-startup-hook
                  (lambda ()
                    (let ((src (expand-file-name "tour.org" user-emacs-directory))
                          (dst (expand-file-name "~/.cache/emacs/tour.org")))
                      (make-directory (file-name-directory dst) t)
                      (unless (file-exists-p dst)
                        (copy-file src dst)
                        (set-file-modes dst #o644))
                      (find-file dst)
                      (org-overview)
                      (goto-char (point-min)))))
      '';
      ".config/emacs/tour.org".text = ''
        #+title: You Are Inside a Lisp Machine
        #+startup: indent

        * Read this first
        This document is folded. Put your cursor on any heading and press
        =TAB= to unfold it. Press =TAB= again to fold it back. That is the
        whole tutorial for reading this file.

        (And yes: =C-x C-c= quits. You now know how to exit Emacs.
        Half the internet's jokes are dead to you.)

        * This document is alive
        This is not a README about Emacs. It is a program you are standing
        inside of. Put your cursor anywhere on the block below and press
        =C-c C-c=:

        #+begin_src emacs-lisp
        (format "This buffer has %d characters, and it is %s."
                (buffer-size)
                (format-time-string "%A at %H:%M"))
        #+end_src

        The result appears under the block. The document just computed part
        of itself. Every code block in this file works the same way.

        * Everything is a searchable function
        Press =M-x= (Alt+x). That prompt can run any of ~10,000 commands, and
        you can type any words in any order to find them — try typing
        =theme load= and pick a theme. The minibuffer annotations you see
        next to each candidate? That's this config being nice to you.

        Emacs is also self-documenting. Press =C-h k= and then press any
        key: Emacs tells you exactly what that key does and links to the
        source code implementing it. The editor will explain itself to you,
        all the way down.

        * Org-mode: the killer app
        ** TODO Cycle me — put your cursor here and press =C-c C-t=
        ** Tables are spreadsheets
        Change a number in the second column, then press =C-c C-c= on the
        =TBLFM= line at the bottom:

        | thing              | hours/week |
        |--------------------+------------|
        | scrolling twitter  |          9 |
        | meetings           |         11 |
        | actual programming |          6 |
        |--------------------+------------|
        | total              |         26 |
        #+tblfm: @5$2=vsum(@2..@4)

        A plain-text table that recalculates itself. People run companies,
        write PhD theses, and track their entire lives in files like this.

        * Magit: git as it should have been
        Run this block (=C-c C-c=) to open Magit on your NixOS config:

        #+begin_src emacs-lisp
        (magit-status "~/nixos")
        #+end_src

        In the Magit buffer: =TAB= expands any file to show its diff, =s=
        stages the thing at point (works on a single hunk!), =c c= commits,
        =q= quits. Most people who try Magit never touch the git CLI again.

        * The shell is in here too
        #+begin_src shell :results output
        nixos-version
        #+end_src

        =C-c C-c=. Shell output, captured into your document. This is how
        people write executable, reproducible notes — the code and the
        prose live in one file.

        * Your NixOS repo is org'd
        =~/nixos/TODO.org= is wired into this Emacs as a project inbox:

        - =C-c c= from *anywhere* — capture a task (=t=), idea (=i=), or
          package to try (=p=); it files itself into TODO.org and drops you
          back where you were
        - =C-c a a= — the agenda: everything scheduled or TODO across your
          org files, compiled into one dashboard
        - =C-c C-t= on a TODO flips it to DONE and logs a timestamp

        The habit that makes people live here: mid-task thought appears,
        =C-c c t=, type it, =C-c C-c=, thought is filed, flow unbroken.

        And the deep end: =C-c n= opens =~/nixos/nixos.org= — your *entire
        system configuration as one literate document*. Every .nix file is
        a source block; =C-c '= edits one with full nix-mode; saving the
        org file tangles them all back to disk. Fold it with =S-TAB= and
        your OS reads like a book's table of contents.

        * Recess
        - =M-x tetris= — yes, really
        - =M-x doctor= — talk to a 1960s psychotherapist about your feelings
        - =M-x zone= — Emacs gets bored and starts melting your text
        - =M-x butterfly= — for xkcd fans

        * The actual point
        Emacs is not a text editor. It is a Lisp interpreter wearing a text
        editor as a costume. Every key you press calls a function; every
        function can be inspected, replaced, or rewritten *while it runs*.
        Nothing is off-limits, which is why, 49 years in, it still does
        things no other tool can.

        You edit your OS with Nix. Emacs is the same idea, pointed at your
        editor. That's the whole pitch.

        This file is your writable copy (=~/.cache/emacs/tour.org=) —
        scribble on it, break it, keep it as your first org file.
      '';
    };
  };
}
