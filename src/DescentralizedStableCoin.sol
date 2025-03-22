// SPDX-License-Identifier: MIT

// Layout of contract 
// version 
// imports
// errors
// interfaces, libraries, contracts 
// type declarations
// state variables
// events
// modifiers
// functions

// Layout of functions 
// constructor 
// receive function (if exists)
// fallback function (if exists)
// external 
// public
// internal 
// private 
// view & pure functions

pragma solidity ^0.8.18;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title DescentralizedStableCoin
 * @author Pacific Typhoon 
 * Collateral: Exogenus (ETH & BTC)
 * Minting: Algorithmic
 * Relative Stability: pegged to USD
 * 
 * This is the contract meant to be governed by DSCEngine. This contract is just the ERC20 implementation of our stable coin system.
 */

contract DescentralizedStableCoin is ERC20Burnable, Ownable {
    error DescentralizedStableCoin_MustBeMoreThanZero();
    error DescentralizedStableCoin_BurnAmountExceedsBalance();
    error DescentralizedStableCoin_NotZeroAddress();

    constructor() ERC20("DescentralizedStableCoin", "DSC") Ownable(msg.sender) {}

    function burn(uint256 _amount) public override onlyOwner {
       uint256 balance = balanceOf(msg.sender);
       if(_amount <= 0) {
           revert DescentralizedStableCoin_MustBeMoreThanZero();
       }
       if(balance < _amount) {
           revert DescentralizedStableCoin_BurnAmountExceedsBalance();
       }
       super.burn(_amount);
    }

    function mint(address _to, uint256 _amount) external onlyOwner returns(bool){
        if(_to == address(0)) {
            revert DescentralizedStableCoin_NotZeroAddress();
        }
        if(_amount <= 0) {
            revert DescentralizedStableCoin_MustBeMoreThanZero();
        }
        _mint(_to, _amount);
        return true;
    }
}