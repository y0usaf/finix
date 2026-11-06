[
  {
    select = ":root:not(#s0):not(#s1) .sf-chat-reader.sf-main > [data-role='omp.assistant'] > .sf-md, :root:not(#s0):not(#s1) .sf-chat-reader.sf-main > [data-role='omp.chat.msg'] > [data-role='omp.assistant'] > .sf-md";
    set = [
      ["background" "var(--modal-bg)"]
      ["-webkit-backdrop-filter" "var(--frost)"]
      ["backdrop-filter" "var(--frost)"]
      ["box-shadow" "var(--frost-edge)"]
      ["--t1" "var(--frost-ink)"]
      ["color" "var(--frost-ink)"]
    ];
  }
]
