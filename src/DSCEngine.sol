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
import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

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
    error DSCEngine__OracleReturnsNegativeAmountForPriceFeed();
    error DSCEngine__BreaksHealthFactor(uint256 userHealthFactor);
    error DSCEngine__MintFailed();

    /////////////////////////
    //////// state variables /////// 
    /////////////////////////
    uint256 private constant ADDITONAL_FEED_PRECISION = 1e10;
    uint256 private constant PRECISION = 1e18;
    // This dive the collateral to calculate the health factor. 
    // For example, a threshold of 50 (=0.5 or 50% of collateral) means that we need the double of collateral than stablecoin
    // because collateral/dsc should be more than 1 ALWAYS. 
    // with no threshold we requiere almost the same amount 1-1
    // If we take only the 50% of collateral (by multiplying it for the liq threshold) we ensure it for always be the double of dsc. If not, the division will give <1 which means a bad health
    uint256 private constant LIQUIDATION_THRESHOLD = 50; 
    uint256 private constant LIQUIDATION_PRECISION = 100; // To convert the threshold to a percentage, for example 50/100 = 0.5 = 50% 
    uint256 private constant MIN_HEALTH_FACTOR = 1;

    mapping(address token => address priceFeed) private s_priceFeeds;
    mapping(address user => mapping(address token => uint256 amount)) private s_collateralDeposited;
    mapping(address user => uint256 amountDSCMinted) private s_dscMinted;
    address[] private s_collateralTokens;

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
            s_collateralTokens.push(tokenAddresses[i]);
        }

        i_dsc = DescentralizedStableCoin(dscAddress);
    }


    /////////////////////////
    //////// External Functions
    /////////////////////////

    /**
     * 
     * @param tokenCollateralAddress The address of the token to deposit collateral 
     * @param amounCollateral The amout of collateral to deposit 
     * @param amountDSCToMint the amount of descentralized stablecoin to mint 
     * @notice This function will deposit your collateral and mint DSC in one transaction
     */
    function  depositCollateralAndMintDSC(
        address tokenCollateralAddress, 
        uint256 amounCollateral,
        uint256 amountDSCToMint
    ) external {
        depositCollateral(tokenCollateralAddress, amounCollateral);
        mintDSC(amountDSCToMint);
    }

    /** 
     * @notice follows CEI (checks, effects, interactions)
     * @param tokenCollateralAddress The address of the token to deposit as collateral
     * @param amountCollateral The amount of collateral to be deposit
     */
    function depositCollateral(
        address tokenCollateralAddress, 
        uint256 amountCollateral
    ) public moreThanZero(amountCollateral) isAllowedToken(tokenCollateralAddress) nonReentrant {
        s_collateralDeposited[msg.sender][tokenCollateralAddress] += amountCollateral;
        emit CollateralDeposited(msg.sender, tokenCollateralAddress, amountCollateral);
    
        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amountCollateral);
        if(!success) {
            revert DSCEngine__TransferFailed();
        }
    }
    
    function redeemCollateralForDSC() external {}

    function redeemCollateral() external {}

    /**
     * 
     * @param amountDSCToMint The amount of descentralize stable coin to mint
     * @notice They must have more collateral value than the minimum threshold 
     */
    function mintDSC(uint256 amountDSCToMint) public moreThanZero(amountDSCToMint) nonReentrant {
        s_dscMinted[msg.sender] += amountDSCToMint;
        _revertIfHealthFactorIsBroken(msg.sender);
        bool minted = i_dsc.mint(msg.sender, amountDSCToMint);
        if(!minted) {
            revert DSCEngine__MintFailed();
        }
    }

    function burnDSC() external {}

    function liquidate() external {}

    function healthFactor(address user) external {}

    /////////////////////////
    //////// Private and Internal view functions
    /////////////////////////

    function _getAccountInformation(address user) private view returns(uint256 totalDSCMinted, uint256 collateralValueInUSD) {
        totalDSCMinted = s_dscMinted[user];
        collateralValueInUSD = getAccountCollateralValue(user);
    }

    /**
     * 
     * Returns how close to liquidation a user is
     * If a user goes below 1, then they can be liquidated
     */
    function _healthFactor(address user) internal view returns(uint256) {
        (uint256 totalDSCMinted, uint256 collateralValueInUSD) = _getAccountInformation(user);
        uint256 collateralAdjustedForThreshold = (collateralValueInUSD * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION; // THRESHOLD% of collateral (50% threshols means we need double, 75% means we need 1.5, etc)
        return collateralAdjustedForThreshold/totalDSCMinted;
    }

    /**
     * @notice "Health factor" term refers to -> do they have enough collateral?
     */
    function _revertIfHealthFactorIsBroken(address user) internal view {
        uint256 userHealthFactor = _healthFactor(user);
        if(userHealthFactor < MIN_HEALTH_FACTOR) {
            revert DSCEngine__BreaksHealthFactor(userHealthFactor);
        }
    }

    /////////////////////////
    //////// Public & external View functions
    /////////////////////////
    function getAccountCollateralValue(address user) public view returns(uint256 totalCollateralValueInUsd) {
        for(uint256 i=0; i<s_collateralTokens.length; i++) {
            address token = s_collateralTokens[i];
            uint256 amount = s_collateralDeposited[user][token];
            totalCollateralValueInUsd += getUSDValue(token, amount);
        }
    }

    function getUSDValue(address token, uint256 amount) public view returns(uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        (,int256 price,,,) = priceFeed.latestRoundData();

        if(price < 0) {
            revert DSCEngine__OracleReturnsNegativeAmountForPriceFeed();
        }
        // example: if 1 ETH = 1000$
        // The returned value will be 1000 * 1e8 (make sure to check the amount of decimals of related conversions on Chainlink docs, it should variate depending on what coins are involved)
        // BUT for ETH and BTC are 8 decimal places 
        return (uint256(price) * ADDITONAL_FEED_PRECISION * amount) / PRECISION; 
    }
}