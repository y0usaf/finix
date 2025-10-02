{
  # literally just so I can use nh
  outputs = _: {
    inherit ((import ./lib)) nixosConfigurations;
  };
}
