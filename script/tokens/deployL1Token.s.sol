// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import {L1ERC20} from "../../src/libraries/token/L1ERC20.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {RoleManager} from "../../src/libraries/access/RoleManager.sol";

contract DeployL1ERC20Token is Script {
    string tokenName;
    uint8 tokenDecimal;
    string tokenSymbol;
    uint256 deployerPrivateKey;
    address roleManagerAddress;

    function setUp() public {
        deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        string memory deployedL1Json = vm.readFile(
            "./script/utils/L1Addresses.json"
        );

        roleManagerAddress = vm.parseJsonAddress(
            deployedL1Json,
            ".L1RoleManager"
        );

        tokenName = vm.envString("TOKEN_NAME");
        tokenSymbol = vm.envString("TOKEN_SYMBOL");
        tokenDecimal = uint8(vm.envUint("TOKEN_DECIMAL"));
    }

    function run() external {
        address initialOwner = vm.addr(deployerPrivateKey);

        address newL1ERC20 = Upgrades.deployTransparentProxy(
            "L1ERC20.sol",
            initialOwner,
            abi.encodeCall(
                L1ERC20.initialize,
                (tokenName, tokenSymbol, tokenDecimal, roleManagerAddress)
            )
        );

        console.log("Token deployed at: ", newL1ERC20);
    }
}
