{lib, ...}: {
  options.hardware = {
    bluetooth = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable Bluetooth support";
      };
    };
    
    nvidia = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable NVIDIA GPU support";
      };
      
      cuda = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable NVIDIA CUDA support";
        };
      };
    };
    
    amdgpu = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable AMD GPU support";
      };
    };
  };
}