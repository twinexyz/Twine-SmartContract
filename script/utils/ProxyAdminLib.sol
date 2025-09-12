// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

library ProxyAdminLib {
    function getProxyAdmin(
        address proxyAddress
    ) internal view returns (ProxyAdmin) {
        address admin = Upgrades.getAdminAddress(proxyAddress);
        return ProxyAdmin(admin);
    }
}
