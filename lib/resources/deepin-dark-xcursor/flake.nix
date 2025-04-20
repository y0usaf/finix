{
  description = "Deepin Dark X11 Cursor Theme";

  outputs = {self}: {
    # We can expose the entire directory as a package source
    xcursorSource = self;
  };
}
