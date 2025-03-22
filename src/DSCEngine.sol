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

/**
 * @title DSCEngine
 * @author Jorge Zerpa 
 * The system is designed to be as minimal as possible, and have the tokens maintain a 1 token == $1 peg.
 * This stablecoin has the properties:
 * - Exogenus Collateral
 * - Dollar Pegged
 * - Algorithmically stable
 * 
 * It is similar to DAI if  DAI had no governace, no fees, adn was only backed by WETH and WBTC
 * 
 * Our DSC system should always be "overcollateralized". At not point should the value of all collateral be less our equal than the backed value of all DSC.
 * 
 * @notice This contract is the core of the DSC System. It handles all the logic for minting and redeeming DSC, as well as depositing & withdrawing collateral.
 * @notice This contract is VERY loosely based on the MakerDAO DSS (DAI) system.
 */

contract DSCEngine {
    function  depositCollateralAndMintDSC() external {}

    function depositCollateral() external {}
    
    function redeemCollateralForDSC() external {}

    function redeemCollateral() external {}

    function mintDSC() external {}
        
    function burnDSC() external {}

    function liquidate() external {}

    function healthFactor() external view {}
}