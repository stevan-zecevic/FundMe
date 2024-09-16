// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import {Test} from "forge-std/Test.sol";
import {FundMeFactory, FundMeFactory__IndexOutOfBounds} from "contracts/FundMeFactory.sol";
import {FundMe_AmountBased} from "contracts/FundMe_AmountBased.sol";
import {DeployFundMeFactory} from "script/DeployFundMeFactory.s.sol";
import {NetworkConfig} from "script/NetworkConfig.s.sol";
import {stdError} from "forge-std/StdError.sol";

contract FundMeFactoryTest is Test {
    NetworkConfig.Config internal s_networkConfig;

    FundMeFactory internal factory;

    bytes32 internal constant NAME = "Amount Based Fundation";
    bytes32 internal constant AMOUNT_DESCRIPTION =
        "This is amount based foundation";
    bytes32 internal constant TIME_DESCRIPTION =
        "This is time based foundation";

    function setUp() external {
        NetworkConfig networkConfig = new NetworkConfig();
        s_networkConfig = networkConfig.getConfig();

        DeployFundMeFactory deployer = new DeployFundMeFactory();
        factory = deployer.deploy();
    }

    function testNumberOfFundations() public view {
        assertEq(factory.getFundationCount(), 0);
    }

    function testGetFundations() public view {
        address[] memory fundations = factory.getFundations();
        assertEq(fundations.length, 0);
    }

    function testFactoryInitialValues() public {
        vm.expectRevert(
            abi.encodeWithSelector(FundMeFactory__IndexOutOfBounds.selector)
        );
        factory.getFundation(0);
    }

    function testCreateAmountBasedFundMe() public {
        uint256 TIME_LIMIT = 0;
        uint256 GOAL_AMOUNT = 1 ether;
        uint256 MINIMUM_FUND_AMOUNT = 1; // 1 USD
        address priceFeedAddress = s_networkConfig.priceFeedAddress;

        address amountBasedFundation = factory.createFundation(
            NAME,
            AMOUNT_DESCRIPTION,
            TIME_LIMIT,
            GOAL_AMOUNT,
            MINIMUM_FUND_AMOUNT,
            priceFeedAddress
        );

        address fundation = factory.getFundation(0);
        uint256 fundationCount = factory.getFundationCount();

        address[] memory fundations = factory.getFundations();
        assertEq(fundations[0], amountBasedFundation);
        assertEq(fundationCount, 1);
        assertEq(fundation, amountBasedFundation);
    }

    function testCreateTimeBasedFundMe() public {
        uint256 TIME_LIMIT = 86400; // in seconds
        uint256 GOAL_AMOUNT = 0;
        uint256 MINIMUM_FUND_AMOUNT = 1; // 1 USD
        address priceFeedAddress = s_networkConfig.priceFeedAddress;

        address timeBasedFundation = factory.createFundation(
            NAME,
            TIME_DESCRIPTION,
            TIME_LIMIT,
            GOAL_AMOUNT,
            MINIMUM_FUND_AMOUNT,
            priceFeedAddress
        );

        address[] memory fundations = factory.getFundations();
        assertEq(fundations[0], timeBasedFundation);
        address fundation = factory.getFundation(0);
        uint256 fundationCount = factory.getFundationCount();

        assertEq(fundationCount, 1);
        assertEq(fundation, timeBasedFundation);
    }
}
