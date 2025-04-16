// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ITwineERC20} from "./ITwineERC20.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract TwineStandardERC20 is ITwineERC20,ERC20Upgradeable{
    address public twineMessenger;
    uint8 private decimals_;

     modifier onlyMessenger() {
        require(twineMessenger == _msgSender(), "Only Messenger");
        _;
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address _twineMessenger
    ) external initializer {
        __ERC20_init(_name, _symbol);

        decimals_ = _decimals;
        twineMessenger = _twineMessenger;
    }


    function decimals() public view override returns (uint8) {
        return decimals_;
    }

    /// @inheritdoc ITwineERC20
    function mint(address _to, uint256 _amount) external onlyMessenger {
        _mint(_to, _amount);
    }

    /// @inheritdoc ITwineERC20
    function burn(address _from, uint256 _amount) external onlyMessenger {
        _burn(_from, _amount);
    }
}
