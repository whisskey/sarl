// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26 <0.9.0;

import { Script } from "forge-std/src/Script.sol";

abstract contract Broadcaster is Script {
    /// @dev Private key of broadcaster who deals with the transaction.
    uint256 internal broadcaster;

    /// @dev It is derived from Anvil's default mnemonic with the index of 0.
    uint256 internal constant DEFAULT_PK = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    /// @dev Assigns the broadcaster's private key from .env file or a default value.
    /// If $DEPLOYER_KEY is defined in .env file, then use it.
    /// Else, use default private key which is derived from Anvil's default mnemonic,
    /// which is "test test test test test test test test test test test junk" with the
    /// index of 0.
    constructor() {
        broadcaster = vm.envOr({ name: "DEPLOYER_PK", defaultValue: DEFAULT_PK });
    }

    modifier broadcast() {
        vm.startBroadcast(broadcaster);
        _;
        vm.stopBroadcast();
    }
}
