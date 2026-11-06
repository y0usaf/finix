[
  {
    select = ".sf-chat-reader [data-role='omp.assistant.note'] > .sf-md .md";
    set = [
      ["font-size" "13px"]
      ["color" "var(--t2)"]
    ];
  }
  {
    select = ".sf-chat-reader [data-role='omp.assistant.note'] > .sf-md .md > :last-child";
    set = [
      ["margin-bottom" "0"]
    ];
  }
  {
    select = ".sf-chat-reader .sf-section[data-role='omp.notice.work'] > .sf-section-head";
    set = [
      ["font-size" "13px"]
      ["color" "var(--t2)"]
    ];
  }
  {
    select = ".sf-chat-reader .sf-section[data-role='omp.notice.work'] > .sf-section-head .sf-t-dim";
    set = [
      ["color" "var(--t4)"]
    ];
  }
  {
    select = ".sf-chat-reader .sf-section[data-role='omp.notice.work'] > .sf-section-body";
    set = [
      ["margin-left" "7px"]
      ["padding-left" "15px"]
      ["box-shadow" "inset 1px 0 0 var(--l2)"]
    ];
  }
]
