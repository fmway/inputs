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
      "https://moku.cachix.org"
      "https://cache.numtide.com"
    ];
    extra-trusted-public-keys = [
      "selector4nix.cachix.org-1:wovVlT07In5JCVz2tFgxPQTLpnN8hZT6P/RwfFcz3KE="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nyx-cache.chaotic.cx:dJxTrgMC3V3cFfyIiBQDQorG6k1LsqurH/srpMSq7qk="
      "moku.cachix.org-1:EnMXp6/uQVI6IRbKW0xEQylSYoV2N4vszOsoW6/Pq1s="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };
  outputs = inputs: import ./outputs.nix inputs;
}