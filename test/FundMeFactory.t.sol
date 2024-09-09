// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import {Test} from "forge-std/Test.sol";
import {FundMeFactory} from "contracts/FundMeFactory.sol";
import {FundMe_AmountBased} from "contracts/FundMe_AmountBased.sol";
import {DeployFundMeFactory} from "script/DeployFundMeFactory.s.sol";
import {NetworkConfig} from "script/NetworkConfig.s.sol";
import {stdError} from "forge-std/StdError.sol";

contract FundMeFactoryTest is Test {
    NetworkConfig.Config internal s_networkConfig;

    FundMeFactory internal factory;

    function setUp() external {
        NetworkConfig networkConfig = new NetworkConfig();
        s_networkConfig = networkConfig.getConfig();

        DeployFundMeFactory deployer = new DeployFundMeFactory();
        factory = deployer.deploy();
    }

    function testFactoryInitialValues() public {
        vm.expectRevert(stdError.indexOOBError);
        factory.getFundation(0);
    }

    function testCreateAmountBasedFundMe() public {
        uint256 TIME_LIMIT = 0;
        uint256 GOAL_AMOUNT = 1 ether;
        uint256 MINIMUM_FUND_AMOUNT = 1; // 1 USD
        address priceFeedAddress = s_networkConfig.priceFeedAddress;

        address amountBasedFundation = factory.createFundation(
            TIME_LIMIT,
            GOAL_AMOUNT,
            MINIMUM_FUND_AMOUNT,
            priceFeedAddress
        );

        address fundation = factory.getFundation(0);

        assertEq(fundation, amountBasedFundation);
    }

    function testCreateTimeBasedFundMe() public {
        uint256 TIME_LIMIT = 86400; // in seconds
        uint256 GOAL_AMOUNT = 0;
        uint256 MINIMUM_FUND_AMOUNT = 1; // 1 USD
        address priceFeedAddress = s_networkConfig.priceFeedAddress;

        address timeBasedFundation = factory.createFundation(
            TIME_LIMIT,
            GOAL_AMOUNT,
            MINIMUM_FUND_AMOUNT,
            priceFeedAddress
        );

        address fundation = factory.getFundation(0);

        assertEq(fundation, timeBasedFundation);
    }
}
