"""slope-line: register the ``line_task`` tool, backed by the ``line`` harness.

Hermes' built-in ``delegate_task`` spawns in-process subagents and its name is hard-wired in the
agent runtime ahead of the tool registry (tool_executor / inline_tool_executors dispatch it
directly), so a plugin cannot replace its executor by registering the same name — the model would
be handed a new schema while the native implementation still ran. This plugin therefore introduces
the distinct name ``line_task``; the deployed config disables the native ``delegation`` toolset so
this is the delegation path (see tools.py).
"""

from . import schemas, tools


def register(ctx) -> None:
    """Register ``line_task``; the name collides with nothing, so no operator grant is needed."""
    ctx.register_tool(
        name="line_task",
        toolset="plugin_slope_line",
        schema=schemas.LINE_TASK,
        handler=lambda args, **kwargs: tools.handle_line_task(args, ctx=ctx, **kwargs),
        description=schemas.LINE_TASK["description"],
    )
