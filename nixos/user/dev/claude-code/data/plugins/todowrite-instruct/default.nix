# todowrite-instruct plugin - TodoWrite usage reminders
{
  name = "todowrite-instruct";
  version = "1.0.0";
  description = "Reminders to use TodoWrite for task tracking";
  author = {
    name = "y0usaf";
  };

  hooks = import ./hooks.nix;
}
