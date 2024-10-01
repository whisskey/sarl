// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26 <0.9.0;

import { Script } from "forge-std/src/Script.sol";

abstract contract Environment is Script {
    /// @dev Deployment modes which are defined according to .env file.
    enum DeploymentMode {
        Production,
        Test
    }

    /// @dev Deployment result that consists deployed contract addresses.
    /// NOTE: Feel free to edit this struct according to your contracts you are intended to deploy.
    struct DeploymentResult {
        address foo;
        address[] mocks;
    }

    /// @dev Holds the result of the deployment.
    DeploymentResult internal result;

    /// @dev An error that is triggered after no deployment mode found in .env file.
    error DeploymentModeNotFound();

    /// @dev Retrieves the deployment mode from the environment variables.
    /// If DEPLOYMENT_MODE is set to "prod", it returns DeploymentMode.Production.
    /// If DEPLOYMENT_MODE is set to "test", it returns DeploymentMode.Test.
    /// Throws DeploymentModeNotFound error if the environment variable is not set or has an invalid value.
    function getDeploymentMode() internal view returns (DeploymentMode) {
        try vm.envString("DEPLOYMENT_MODE") returns (string memory mode) {
            bytes32 modeHash = keccak256(abi.encodePacked(mode));

            if (keccak256("prod") == modeHash) {
                return DeploymentMode.Production;
            } else if (keccak256("test") == modeHash) {
                return DeploymentMode.Test;
            } else {
                revert DeploymentModeNotFound();
            }
        } catch {
            revert DeploymentModeNotFound();
        }
    }

    /// @dev Adds a mock contract address to the deployment results.
    /// @param mockAddr The address of the mock contract to add.
    function addMock(address mockAddr) internal {
        result.mocks.push(mockAddr);
    }
}
