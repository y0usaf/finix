Okay, let's create a comprehensive to-do list starting from the original state of y0usaf's codebase, detailing the steps to convert it to the `cfg`-driven configuration pattern used by fazzi. This list makes no assumptions about prior changes.

**Goal:** Refactor y0usaf's configuration so that shared modules define explicit configuration options under `options.cfg.*` and access configuration values provided by the host profiles via `config.cfg.*`.

**Starting Point:** The original y0usaf codebase provided in the first prompt.

---

**Refactoring To-Do List: Implementing `cfg`-Driven Configuration**

**Phase 1: Preparation & Initial Structure Changes**

1.  **[ ] Version Control:**
    *   Ensure you are in the root directory of the y0usaf codebase.
    *   Create a new Git branch: `git checkout -b refactor-cfg-pattern`
    *   Commit the current state if you haven't already.

2.  **[ ] Rename Configuration Block in Host Profiles:**
    *   **Edit `profiles/y0usaf-desktop/default.nix`:**
        *   Find the top-level `modules = { ... };` attribute set.
        *   Rename `modules` to `cfg`. The internal structure stays the same for now.
        ```nix
        # Change this:
        {
          modules = {
             system = { ... };
             # ...
          };
        }
        # To this:
        {
          cfg = {
             system = { ... };
             # ...
          };
        }
        ```
    *   **Edit `profiles/y0usaf-laptop/default.nix`:**
        *   Perform the identical rename (`modules` -> `cfg`).
    *   **Commit:** `git add profiles/*; git commit -m "Phase 1: Rename profile config blocks to 'cfg'"`

**Phase 2: Adjust Flake & Integration Layers**

1.  **[ ] Modify Flake Helper (`modules/flake/profiles.nix`):**
    *   **Pass `cfg` via `extraSpecialArgs` for Home Manager:**
        *   Locate the `home-manager` block within the `mkNixosConfigurations` function.
        *   Modify the `extraSpecialArgs` line:
            ```nix
            # Change this:
            # extraSpecialArgs = commonSpecialArgs // { profile = profiles.${hostname}; };
            # To this (choose a name like 'userCfg' or 'hostCfg'):
            extraSpecialArgs = commonSpecialArgs // {
              profile = profiles.${hostname}; # Keep profile if other parts need it
              userCfg = profiles.${hostname}.cfg; # Pass the new cfg structure
            };
            ```
    *   **Pass `cfg` via `specialArgs` for NixOS (if needed by custom system modules):**
        *   Locate the main `specialArgs` for `nixosSystem`.
        *   If your custom *system* modules under `modules/system/` directly referenced `profile.modules` for non-standard configuration (which they generally shouldn't, but check), you need to pass `cfg` here too.
            ```nix
            # Change this:
            # specialArgs = commonSpecialArgs // { profile = profiles.${hostname}; };
            # To this (if needed):
            specialArgs = commonSpecialArgs // {
              profile = profiles.${hostname};
              userCfg = profiles.${hostname}.cfg; # Use the same name as for HM
            };
            ```

2.  **[ ] Define and Populate `config.cfg` in Home Manager Root (`home.nix`):**
    *   Edit `home.nix`.
    *   Modify the function arguments to accept the configuration passed via `extraSpecialArgs`:
        ```nix
        # Change function signature, e.g.:
        { config, pkgs, lib, inputs, profile, ... }: # OLD
        { config, pkgs, lib, inputs, profile, userCfg, ... }: # NEW (add userCfg)
        ```
    *   Add the `options.cfg` definition within the main attribute set:
        ```nix
        {
          # ... (arguments) ...
        }: {
          # --> ADD this block <--
          options.cfg = lib.mkOption {
            type = lib.types.attrs; # Be more specific later if possible
            default = {};
            description = "User-defined configuration passed from the host profile.";
            readOnly = true; # Good practice for config passed this way
          };
          # --> END ADD <--

          imports = [./modules/home];

          # --> ADD this line <--
          config.cfg = userCfg;
          # --> END ADD <--

          # --> REMOVE or COMMENT OUT this line <--
          # modules = profile.modules or {};
        }
        ```

3.  **[ ] Define and Populate `config.cfg` in NixOS Root (If Needed) (`profiles/configurations/default.nix`):**
    *   Edit `profiles/configurations/default.nix`.
    *   If system modules need the `cfg` data (Step 1 above), modify the arguments and add the option definition and assignment similar to Step 2.
        ```nix
        # Change function signature, e.g.:
        { config, lib, pkgs, profile, inputs, ... }: # OLD
        { config, lib, pkgs, profile, inputs, userCfg, ... }: # NEW (add userCfg)
        ```
        ```nix
        {
          # ... (arguments) ...
        }: {
          # --> ADD if needed <--
          options.cfg = lib.mkOption {
            type = lib.types.attrs;
            default = {};
            description = "User-defined configuration passed from the host profile.";
            readOnly = true;
          };

          config.cfg = userCfg; # Assign from specialArgs
          # --> END ADD <--

          imports = [ ../../modules/system ];
        }
        ```
4.  **[ ] Commit:** `git add modules/flake/profiles.nix home.nix profiles/configurations/default.nix; git commit -m "Phase 2: Adjust flake and integration layers for cfg"`

**Phase 3: Refactor Shared Modules (The Core Task)**

*   **Strategy:** Work through modules one by one or in small, related groups. Build (`nixos-rebuild build --flake .#hostname`) after each group to catch errors.
*   **Pattern for each module (`modules/home/*/*.nix`, relevant `modules/system/*/*.nix`):**

    1.  **[ ] **Step 3a: Define Options:**
        *   At the top level of the module's return value (the attribute set), add an `options` block.
        *   Mirror the structure expected from the profile, but under `cfg`. For example, for `modules/home/apps/discord.nix`, add:
            ```nix
            options.cfg.apps.discord = {
              enable = lib.mkEnableOption "Discord Canary module";
              # If discord module used other config like a specific path:
              # somePath = lib.mkOption { type = lib.types.str; default = "/default"; description = "..."; };
            };
            ```
        *   For *every* value the module previously read from `config.modules.*` or `profile.modules.*`, define a corresponding `lib.mkOption` here with the correct `type`, a `description`, and ideally a sensible `default` if applicable.

    2.  **[ ] **Step 3b: Update Configuration Access:**
        *   Search the *entire module file* for references to `config.modules.*` or `profile.modules.*`.
        *   Replace them with references to `config.cfg.*`.
        *   **Examples:**
            *   `lib.mkIf config.modules.apps.discord.enable` -> `lib.mkIf config.cfg.apps.discord.enable`
            *   `let cfg = config.modules.apps.discord;` -> `let cfg = config.cfg.apps.discord;`
            *   `someValue = config.modules.apps.discord.somePath;` -> `someValue = config.cfg.apps.discord.somePath;`
            *   `lib.mkIf profile.modules.core.nvidia.enable` -> `lib.mkIf config.cfg.core.nvidia.enable`
            *   `userName = cfg.name;` (where cfg pointed to `config.modules.core.git`) -> `userName = config.cfg.core.git.name;` (or `cfg.name` if you updated the `let cfg = ...` line).
        *   Be meticulous! Check variable assignments, conditional logic (`lib.mkIf`), string interpolations, etc.

    3.  **[ ] **Step 3c: Commit (Incrementally):** After refactoring a module or small group:
        ```bash
        git add modules/home/apps/discord.nix # Add specific files
        git commit -m "Phase 3: Refactor discord module to use cfg pattern"
        # Try building: nixos-rebuild build --flake .#y0usaf-desktop
        ```

*   **Modules to Refactor (Apply pattern above to each):**
    *   **[ ] `modules/home/apps/*`:** (android, chatgpt, creative, discord, firefox, gaming, media, music, obs, qbittorrent, spotdl, streamlink, sway-launcher-desktop, syncthing, webapps, yt-dlp, zen-browser)
    *   **[ ] `modules/home/core/*`:** (appearance, core, env, fonts, git, nh, ssh, systemd, xdg, zellij, zsh) - `core.nix` and `fonts.nix` require careful handling as they aggregate settings.
    *   **[ ] `modules/home/dev/*`:** (claude-code, cuda, cursor-ide, dev-fhs, docker, mcp, npm, nvim, python, voice-input)
    *   **[ ] `modules/home/ui/*`:** (ags, cursor, foot, gtk, hyprland, mako, wallust, wayland)
    *   **[ ] `modules/system/*`:** Review these for any direct use of `profile.modules` or `config.modules` (unlikely for standard settings, but possible in `lib.mkIf` or custom logic). Update accesses like `profile.modules.core.nvidia.enable` to `config.cfg.core.nvidia.enable`.

**Phase 4: Final Testing and Verification**

1.  **[ ] Full Build:** Once all modules seem refactored, perform a final build for both hosts:
    ```bash
    nixos-rebuild build --flake .#y0usaf-desktop
    nixos-rebuild build --flake .#y0usaf-laptop
    ```
    Fix any remaining evaluation errors.
2.  **[ ] Comprehensive Runtime Test:** Boot into the new configurations (VM or bare metal). Test a wide range of features:
    *   Login works.
    *   Hyprland starts, keybindings work, theme applies (if applicable via GTK/Wallust).
    *   Core apps launch (terminal, browser, file manager).
    *   Enabled apps/services start correctly (Discord, Syncthing, development tools).
    *   Check system settings (fonts, GPU drivers, networking).
    *   Test features that cross module boundaries (e.g., Zsh aliases pointing to commands from other modules).
3.  **[ ] Debug:** Address any runtime issues found.

**Phase 5: Cleanup and Merge**

1.  **[ ] Code Review:** Read through the changed files. Ensure consistency and clarity. Check for any remaining `config.modules` references.
2.  **[ ] Merge:** If satisfied, merge the `refactor-cfg-pattern` branch into your main branch. `git checkout main; git merge refactor-cfg-pattern`
3.  **[ ] Remove Old Branch:** `git branch -d refactor-cfg-pattern`

---

This systematic approach should guide you through the refactoring process. Remember to take breaks, test frequently, and commit often!
