// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract Create2DeployFactory {
    event ProxyDeployed(address indexed proxy, bytes32 salt);

    function deployProxy(
        address logic,
        address admin,
        bytes memory data,
        bytes32 salt
    ) public returns (address) {
        bytes memory bytecode = abi.encodePacked(
            type(TransparentUpgradeableProxy).creationCode,
            abi.encode(logic, admin, data)
        );

        address proxy;
        assembly {
            proxy := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        require(proxy != address(0), "Create2: Failed on deploy");
        emit ProxyDeployed(proxy, salt);
        return proxy;
    }

    function computeAddress(
        address logic,
        address admin,
        bytes memory data,
        bytes32 salt
    ) public view returns (address) {
        bytes memory bytecode = abi.encodePacked(
            type(TransparentUpgradeableProxy).creationCode,
            abi.encode(logic, admin, data)
        );

        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(bytecode)
            )
        );

        return address(uint160(uint(hash)));
    }
}
