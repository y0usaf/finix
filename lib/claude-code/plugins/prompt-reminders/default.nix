# prompt-reminders plugin - behavior nudges on user prompt submit
{
  name = "prompt-reminders";
  version = "1.0.0";
  description = "Behavioral reminders injected on each user prompt";
  author = {
    name = "y0usaf";
  };

  hooks = import ./hooks.nix;
}
