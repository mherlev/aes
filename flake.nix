{
  description = "Verilog implementation of AES (NIST FIPS 197)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
    in
    {
      devShells = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            packages = [ pkgs.iverilog pkgs.verilator pkgs.python3 ];
          };
        });

      packages = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};

          mkSim = name: srcs: pkgs.stdenv.mkDerivation {
            pname = name;
            version = "0.60";
            src = self;
            nativeBuildInputs = [ pkgs.iverilog ];
            buildPhase = "iverilog -Wall -o ${name} ${srcs}";
            installPhase = ''
              mkdir -p $out/bin
              cp ${name} $out/bin/${name}
            '';
          };

          rtl = "src/rtl";
          tb  = "src/tb";
        in
        {
          top      = mkSim "top.sim"      "${tb}/tb_aes.v ${rtl}/aes.v ${rtl}/aes_core.v ${rtl}/aes_key_mem.v ${rtl}/aes_sbox.v ${rtl}/aes_inv_sbox.v ${rtl}/aes_encipher_block.v ${rtl}/aes_decipher_block.v";
          core     = mkSim "core.sim"     "${tb}/tb_aes_core.v ${rtl}/aes_core.v ${rtl}/aes_key_mem.v ${rtl}/aes_sbox.v ${rtl}/aes_inv_sbox.v ${rtl}/aes_encipher_block.v ${rtl}/aes_decipher_block.v";
          keymem   = mkSim "keymem.sim"   "${tb}/tb_aes_key_mem.v ${rtl}/aes_key_mem.v ${rtl}/aes_sbox.v";
          encipher = mkSim "encipher.sim" "${tb}/tb_aes_encipher_block.v ${rtl}/aes_encipher_block.v ${rtl}/aes_sbox.v";
          decipher = mkSim "decipher.sim" "${tb}/tb_aes_decipher_block.v ${rtl}/aes_decipher_block.v ${rtl}/aes_inv_sbox.v";

          default  = mkSim "top.sim"      "${tb}/tb_aes.v ${rtl}/aes.v ${rtl}/aes_core.v ${rtl}/aes_key_mem.v ${rtl}/aes_sbox.v ${rtl}/aes_inv_sbox.v ${rtl}/aes_encipher_block.v ${rtl}/aes_decipher_block.v";
        });
    };
}
