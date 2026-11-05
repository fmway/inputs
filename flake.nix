{
  description = "fmway/inputs — clean, input-less flake rerouting collected flake inputs through fake derivations";

  # Empty by design: the ./dev flake owns every pin and its lock is resolved
  # into inputs here at eval time, so this flake never writes a flake.lock.
  inputs = { };
  nixConfig = {
    extra-substituters = [
      "https://selector4nix.cachix.org/"
      "https://nix-community.cachix.org"
      "https://nyx-cache.chaotic.cx/"
      "https://noctalia.cachix.org"
      "https://cache.numtide.com"
      "https://umbriel.cachix.org"
    ];
    extra-trusted-public-keys = [
      "selector4nix.cachix.org-1:wovVlT07In5JCVz2tFgxPQTLpnN8hZT6P/RwfFcz3KE="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nyx-cache.chaotic.cx:dJxTrgMC3V3cFfyIiBQDQorG6k1LsqurH/srpMSq7qk="
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      "umbriel.cachix.org-1:JfNq/2yg2S6D6z4Z2dVSZrZlDPQTKtexB6GAVLD98nw="
      "fmcachix.cachix.org-1:Z5j9jk83ctoCK22EWrbQL6AAP3CTYnZ/PHljlYSakrw="
    ];
    extra-trusted-substituters = [
      "https://fmcachix.cachix.org"
    ];
  };
  outputs = inputs: import ./default.nix;
}