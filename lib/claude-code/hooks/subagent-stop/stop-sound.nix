''
  #!/usr/bin/env bun
  const { runHook, playSound } = await import(
    `''${process.env.HOME}/.claude/hooks/utils.ts`
  );

  runHook("subagent_stop.json", async (data: { stop_hook_active?: boolean }) => {
    // Skip sound during session init
    if (data.stop_hook_active === false) return;

    await playSound("on-agent-complete.wav");
  });
''
