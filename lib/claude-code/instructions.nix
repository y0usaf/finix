''
  <system>
    <environment>NixOS</environment>
    <rules>
      <rule>Use <code>nix shell nixpkgs#package</code> to run tools not on the system.</rule>
      <rule>Use <code>bun</code> and <code>bunx</code> instead of npm, npx, or yarn.</rule>
      <rule>Use CLIs for external services (e.g. linear, vercel, gh) over API calls or web interfaces.</rule>
    </rules>
  </system>
''
