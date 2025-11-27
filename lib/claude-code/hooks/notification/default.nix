''
  #!/usr/bin/env bun
  const { runHook, playSound, hasFlag } = await import(
    `''${process.env.HOME}/.claude/hooks/utils.ts`
  );

  runHook("notifications.json", async () => {
    if (hasFlag("--notify")) {
      await playSound("on-agent-need-attention.wav");
    }
  });
''
