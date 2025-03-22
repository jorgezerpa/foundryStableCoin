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

import { DescentralizedStableCoin } from "./DescentralizedStableCoin.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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

contract DSCEngine is ReentrancyGuard {

    /////////////////////////
    //////// errors /////// 
    /////////////////////////
    error DSCEngine__NeedsMoreThanZero();
    error DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSamelength();
    error DSCEngine__TokenNotAllowed();
    error DSCEngine__TransferFailed();

    /////////////////////////
    //////// state variables /////// 
    /////////////////////////
    mapping(address token => address priceFeed) private s_priceFeeds;
    mapping(address user => mapping(address token => uint256 amount)) private s_collateralDeposited;

    DescentralizedStableCoin private immutable i_dsc;

    /////////////////////////
    //////// Events /////// 
    /////////////////////////
    event CollateralDeposited(address indexed user, address indexed token, uint256 amount);

    /////////////////////////
    //////// Modifiers /////// 
    /////////////////////////
    modifier moreThanZero(uint256 amount) {
        if(amount==0) {
            revert DSCEngine__NeedsMoreThanZero();
        }
        _;
    }

    modifier isAllowedToken(address token) {  
        if(s_priceFeeds[token] == address(0)) {

        }      
        _;
    }

    /////////////////////////
    //////// Functions /////// 
    /////////////////////////
    constructor(
        address[] memory tokenAddresses, 
        address[] memory priceFeeds,
        address dscAddress
    ) {
        if(tokenAddresses.length != priceFeeds.length) {
            revert DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSamelength();
        }

        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            s_priceFeeds[tokenAddresses[i]] = priceFeeds[i];
        }

        i_dsc = DescentralizedStableCoin(dscAddress);
    }


    /////////////////////////
    //////// External Functions
    /////////////////////////
    function  depositCollateralAndMintDSC() external {}

    /** 
     * @notice follows CEI (checks, effects, interactions)
     * @param tokenCollateralAddress The address of the token to deposit as collateral
     * @param amountCollateral The amount of collateral to be deposit
     */
    function depositCollateral(
        address tokenCollateralAddress, 
        uint256 amountCollateral
    ) external moreThanZero(amountCollateral) isAllowedToken(tokenCollateralAddress) nonReentrant {
        s_collateralDeposited[msg.sender][tokenCollateralAddress] += amountCollateral;
        emit CollateralDeposited(msg.sender, tokenCollateralAddress, amountCollateral);
    
        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amountCollateral);
        if(!success) {
            revert DSCEngine__TransferFailed();
        }
    }
    
    function redeemCollateralForDSC() external {}

    function redeemCollateral() external {}

    function mintDSC() external {}

    function burnDSC() external {}

    function liquidate() external {}

    function healthFactor() external view {}
}