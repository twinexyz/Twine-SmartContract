// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/**
 * @title TypeConversionLib
 * @notice TypeConversionLib contains different conversion functions .
 **/
library TypeConversionLib {
    /// @notice Converts an Ethereum address to its string representation
    ///  @param _address The Ethereum address to convert
    function addressToString(
        address _address
    ) internal pure returns (string memory) {
        bytes32 _bytes = bytes32(uint256(uint160(_address)));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _string = new bytes(42);
        _string[0] = "0";
        _string[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            _string[2 + i * 2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _string[3 + i * 2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }
        return string(_string);
    }

    /// @notice Converts a string representation of an Ethereum address to its address type
    /// @dev Requires the input string to be a valid Ethereum address format (0x followed by 40 hexadecimal characters)
    /// @param _addressString The string representation of an Ethereum address
    function stringToAddress(
        string memory _addressString
    ) internal pure returns (address) {
        bytes memory stringBytes = bytes(_addressString);
        require(
            stringBytes.length == 42 &&
                stringBytes[0] == "0" &&
                stringBytes[1] == "x",
            "Invalid address format"
        );

        uint160 result = 0;
        for (uint256 i = 2; i < 42; i++) {
            result *= 16;
            uint8 digit = uint8(stringBytes[i]);
            if (digit >= 48 && digit <= 57) {
                result += (digit - 48);
            } else if (digit >= 65 && digit <= 70) {
                result += (digit - 55);
            } else if (digit >= 97 && digit <= 102) {
                result += (digit - 87);
            } else {
                revert("Invalid character in address string");
            }
        }
        return address(result);
    }

    /// @notice Converts a string representation of a number to a uint256
    /// @dev Reverts if the input string contains non-numeric characters
    /// @param s The string representation of a number
    function stringToUint(
        string memory s
    ) internal pure returns (uint256 result) {
        bytes memory b = bytes(s);
        uint256 oldResult = 0;
        for (uint256 i = 0; i < b.length; i++) {
            // c = b[i] was not needed
            if (uint8(b[i]) >= 48 && uint8(b[i]) <= 57) {
                // store old value so we can check for overflows
                oldResult = result;
                result = result * 10 + (uint8(b[i]) - 48);
                if (oldResult > result) {
                    // we can only get here if the result overflowed and is smaller than last stored value
                    revert("Invalid String");
                }
            } else {
                revert("InvalidStringNumber");
            }
        }
    }
}
