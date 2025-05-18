{
  description = "Fast Font Collection";

  outputs = {self}: {
    # We can expose the entire directory as a package source
    fastFontSource = self;
  };
}