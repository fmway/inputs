{
  description = "fmway/inputs — clean, input-less flake rerouting collected flake inputs through fake derivations";

  # Empty by design: the ./dev flake owns every pin and its lock is resolved
  # into inputs here at eval time, so this flake never writes a flake.lock.
  inputs = { };
  nixConfig = {
    extra-substituters = [
      "https://moku.cachix.org"
      "https://cache.numtide.com"
    ];
    extra-trusted-public-keys = [
      "moku.cachix.org-1:EnMXp6/uQVI6IRbKW0xEQylSYoV2N4vszOsoW6/Pq1s="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };
  outputs = inputs: import ./outputs.nix inputs;
}