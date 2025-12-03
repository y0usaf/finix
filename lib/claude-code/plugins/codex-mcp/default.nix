# codex-mcp plugin - OpenAI Codex MCP server integration
{
  name = "codex-mcp";
  version = "1.0.0";
  description = "OpenAI Codex MCP server for second opinions and reasoning";
  author = {
    name = "y0usaf";
  };

  mcpServers = {
    codex = {
      command = "bunx";
      args = [
        "--bun"
        "@openai/codex"
        "mcp-server"
        "-c"
        "model=gpt-5.1-codex"
        "-c"
        "model_reasoning_effort=high"
      ];
    };
  };
}
