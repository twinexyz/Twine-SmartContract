// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "forge-std/Script.sol";

import {MockOApp} from "./MockOApp.sol";
import { ILayerZeroEndpointV2 } from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import {SetConfigParam} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/IMessageLibManager.sol";
import {UlnConfig} from "@layerzerolabs/lz-evm-messagelib-v2/contracts/uln/UlnBase.sol";

contract MockOAppScript is Script {
    MockOApp mockApp;
    ILayerZeroEndpointV2 EndpointV2;

    uint32 holeskyEndPointId;
    uint32 receiveConfigType;
    uint32 sepoliaEndPointId;
    address sendLibraryAddress;
    address mockAppAddress;
    address srcEndPointAddress;
    address holeskyCounterAppAddress;
    address sepoliaCounterAppAddress;
    address sepoliaReceiveLibrary;

    function setUp() external {
        srcEndPointAddress = 0x6EDCE65403992e310A62460808c4b910D972f10f; //holesky
        holeskyEndPointId = 40217;
        sepoliaEndPointId = 40161;
        holeskyCounterAppAddress = 0x29c8846BEF1683B32Ed34C9Ec68706001ff4390A;
        sepoliaCounterAppAddress = 0x249B7159576Ef5e28B5D2dBcf667a34039eE1581;
        receiveConfigType = 2;
        sendLibraryAddress = 0x21F33EcF7F65D61f77e554B4B4380829908cD076;
        sepoliaReceiveLibrary = 0xdAf00F5eE2158dD58E0d3857851c432E34A3A851;
    }
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address owner = vm.addr(deployerPrivateKey);
        srcEndPointAddress = 0x6EDCE65403992e310A62460808c4b910D972f10f;
        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        mockApp = new MockOApp(srcEndPointAddress, owner);
        mockApp = MockOApp(holeskyCounterAppAddress);
        mockApp = MockOApp(sepoliaCounterAppAddress);

        MockOApp(sepoliaCounterAppAddress).setPeer(holeskyEndPointId, addressToBytes32(holeskyCounterAppAddress));
        MockOApp(holeskyCounterAppAddress).setPeer(sepoliaEndPointId, addressToBytes32(sepoliaCounterAppAddress));
        MockOApp(holeskyCounterAppAddress).send{value: 1000000000000000000}(
            sepoliaEndPointId,
            "Hello Twine Team",
            hex"0003010011010000000000000000000000000000c350"
        );
        ILayerZeroEndpointV2 endpoint = ILayerZeroEndpointV2(address(mockApp.endpoint()));
        address[] memory requireDvnAddress = new address[](1);
        address[] memory optionalDvnAddress = new address[](1);
 
        requireDvnAddress[0] = 0x8eebf8b423B73bFCa51a1Db4B7354AA0bFCA9193;
        optionalDvnAddress[0] = 0x952f7a8766f134817DF73301900b6A22Ae9C7250;
     

        UlnConfig memory ulnConfigData = UlnConfig({
            confirmations: 2,
            requiredDVNCount: 1,
            optionalDVNCount: 1,
            optionalDVNThreshold: 1,
            requiredDVNs: requireDvnAddress,
            optionalDVNs: optionalDvnAddress
        });
        SetConfigParam[] memory setConfigParams = new SetConfigParam[](1);
        setConfigParams[0] = SetConfigParam({
            eid: holeskyEndPointId,
            configType: receiveConfigType,
            config: abi.encode(ulnConfigData)
        });
        endpoint.setConfig(holeskyCounterAppAddress, sendLibraryAddress, setConfigParams);
        endpoint.setConfig(sepoliaCounterAppAddress, sepoliaReceiveLibrary, setConfigParams);

        // EndpointV2.setConfig(mockApp, sendLibrary, sendConfig);
        // EndpointV2.setConfig(mockApp, receiveLibrary, receiveConfig);

        // Stop broadcasting transactions
        vm.stopBroadcast();
    }

    function addressToBytes32(address _addr) public pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }
}

