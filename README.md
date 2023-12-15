# cloudflare dynamic dns script wrapped as nixpkg

Simple nix pkgs to update a given record with the current public ip.

USAGE:

```sh
nix run .#cfddns <record> <token>
```
