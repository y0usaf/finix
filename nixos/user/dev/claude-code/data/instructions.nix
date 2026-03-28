''
  <system>
    <environment>NixOS</environment>
    <rules>
      <rule>Use <code>nix shell -p <package></code> to run tools not on the system.</rule>
      <rule>Use <code>bun</code> and <code>bunx</code> instead of npm, npx, or yarn.</rule>
      <rule>Use CLIs for external services (e.g. linear, vercel, gh) over API calls or web interfaces.</rule>
      <rule>For Linear tasks, use the <code>linear</code> CLI and do not use a Linear MCP server.</rule>
    </rules>
  </system>
''
