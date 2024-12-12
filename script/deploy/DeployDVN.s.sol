// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {OApp, Origin, MessagingFee} from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import {TwineDVN} from "../../src/lzdvn/TwineDVN.sol";
import {RoleManager} from "../../src/libraries/access/RoleManager.sol";
contract DeployDVN is Script {
    TwineDVN twineDVN;

    address twineDVNAddress;
    address roleManagerAddress;
    address layerZeroEndpointV2;
    address layerZeroEndpointV1;

    function setUp() external {
        roleManagerAddress = 0xBDb6B9fbca80397B18e13bEFfE668e757ecDDfe6;
        layerZeroEndpointV2 = 0x6EDCE65403992e310A62460808c4b910D972f10f;
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address initialOwner = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);
        twineDVNAddress = Upgrades.deployTransparentProxy(
            "TwineDVN.sol",
            initialOwner,
            abi.encodeCall(
                TwineDVN.initialize,
                (layerZeroEndpointV2, roleManagerAddress)
            )
        );
         // Logging the address of the deployed proxies
        console.log("Deployed Contracts :");

        console.log("Twine DVN Address :", twineDVNAddress);
        vm.stopBroadcast();
    }
}

