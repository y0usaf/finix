{
  layout = {
    _args = ["alias=music"];
    default_tab_template = {
      _children = [
        {
          pane = {
            _args = ["size=1" "borderless=true"];
            plugin = {
              _args = ["location=zellij:tab-bar"];
            };
          };
        }
        {
          children = {};
        }
        {
          pane = {
            _args = ["size=2" "borderless=true"];
            plugin = {
              _args = ["location=zellij:status-bar"];
            };
          };
        }
      ];
    };
    tab = {
      _args = ["name=Music"];
      pane = {
        _args = ["split_direction=vertical"];
        _children = [
          {
            pane = {
              _args = ["command=cmus"];
            };
          }
          {
            pane = {
              _args = ["command=cava"];
            };
          }
        ];
      };
    };
  };
}