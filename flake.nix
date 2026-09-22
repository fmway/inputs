{
  description = "fmway/inputs — clean, input-less flake rerouting collected flake inputs through fake derivations";

  # Empty by design: the ./dev flake owns every pin and its lock is resolved
  # into inputs here at eval time, so this flake never writes a flake.lock.
  inputs = { };

  outputs = inputs: import ./outputs.nix inputs;
}
