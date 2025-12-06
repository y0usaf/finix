# instruct-self-review plugin - Review all file changes with critical principles
{
  name = "instruct-self-review";
  version = "1.0.0";
  description = "Stop hook that instructs to review all file changes with critical minimalism principles";
  author = {
    name = "y0usaf";
  };

  hooks = import ./hooks.nix;
}
