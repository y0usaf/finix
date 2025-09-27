_: {
  mcpConfig = {
    mcpServers = {
      codex = {
        command = "codex";
        args = ["mcp"];
        env = {};
      };
      gemini = {
        command = "npx";
        args = ["-y" "@opper/gemini-mcp"];
        env = {};
      };
    };
  };
}
