{config}: [
  {
    name = "Filesystem";
    command = "npx";
    args = ["-y" "@modelcontextprotocol/server-filesystem" config.user.homeDirectory];
    environment = {};
  }
  {
    name = "GitHub Repo MCP";
    command = "npx";
    args = ["-y" "github-repo-mcp"];
    environment = {};
  }
  {
    name = "Gemini MCP";
    command = "npx";
    args = ["-y" "gemini-mcp-tool"];
    environment = {};
  }
]
