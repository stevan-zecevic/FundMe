// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import {FundMe_AmountBased} from "contracts/FundMe_AmountBased.sol";
import {FundMe, FundMe__GoalAmountNotMet, FundMe__RetreiveError, FundMe__FundRequirementNotMet, FundMe__Fallback} from "contracts/FundMe.sol";
import {Ownable, Ownable__NotOwner} from "contracts/Ownable.sol";
import {MockV3Aggregator} from "test/mock/MockV3Aggregator.t.sol";
import {NetworkConfig} from "script/NetworkConfig.s.sol";
import {RevertingOwner} from "test/RevertingOwner.sol";
import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";

contract FundMe_AmountBasedTest is Test {
    event FundMe__Funded(
        address indexed funderAddress,
        uint256 indexed fundedAmount
    );
    event FundMe__DonationsCollected(uint256 indexed amount);

    FundMe_AmountBased s_fundMe;
    NetworkConfig.Config internal s_networkConfig;

    function setUp() external {
        NetworkConfig networkConfig = new NetworkConfig();
        s_networkConfig = networkConfig.getConfig();

        vm.startBroadcast();
        s_fundMe = new FundMe_AmountBased(
            1 ether,
            1,
            s_networkConfig.priceFeedAddress
        );
        vm.stopBroadcast();
    }

    function testInitialContractValues() public view {
        uint256 goalAmount = s_fundMe.getGoalAmount();
        address owner = s_fundMe.getOwner();
        uint256 numberOfFunders = s_fundMe.getNumberOfFunders();
        uint256 firstFunderAmount = s_fundMe.getFundersAmount(msg.sender);
        FundMe.Status fundMeStatus = s_fundMe.getStatus();
        uint256 minimumFund = s_fundMe.getMinimumFund();

        assertEq(goalAmount, 1 ether);
        assertEq(owner, msg.sender);
        assertEq(numberOfFunders, 0);
        assertEq(firstFunderAmount, 0);
        assertEq(uint256(fundMeStatus), 0);
        assertEq(minimumFund, 1);
    }

    function testFundZeroAmount() public {
        FundMe.Status status = s_fundMe.getStatus();

        vm.expectRevert(
            abi.encodeWithSelector(
                FundMe__FundRequirementNotMet.selector,
                address(this),
                uint256(status),
                0,
                0
            )
        );
        s_fundMe.fund{value: 0}();
    }

    function testSuccessfulFund() public {
        uint256 fundedAmount = 5e14;
        uint256 fundedAmountInUSD = s_fundMe.convertToUSD(fundedAmount);

        vm.expectEmit(true, true, false, false);

        emit FundMe__Funded(address(this), fundedAmountInUSD);

        s_fundMe.fund{value: fundedAmount}();

        address funder = s_fundMe.getFunder(0);
        uint256 numberOfFunders = s_fundMe.getNumberOfFunders();
        uint256 amount = s_fundMe.getFundersAmount(funder);

        assertEq(funder, address(this));
        assertEq(numberOfFunders, 1);
        assertEq(amount, fundedAmount);
        assertEq(address(s_fundMe).balance, fundedAmount);
    }

    function testSetingStatus() public {
        FundMe.Status currentStatus = s_fundMe.getStatus();

        s_fundMe.setStatus(FundMe.Status.Closed);
        FundMe.Status newStatus = s_fundMe.getStatus();

        assertNotEq(uint256(currentStatus), uint256(newStatus));
        assertEq(uint256(newStatus), uint256(FundMe.Status.Closed));
    }

    function testFallbackFunction() public {
        bytes memory data = abi.encodeWithSignature("nonExistentFunction()");
        vm.expectRevert(
            abi.encodeWithSelector(FundMe__Fallback.selector, data)
        );
        (bool sent, ) = address(s_fundMe).call(data);
    }

    function testOnlyOnwerCanRetrieveFunds() public {
        vm.expectRevert(
            abi.encodeWithSelector(Ownable__NotOwner.selector, address(this))
        );

        s_fundMe.performUpkeep("");
    }

    function testRetreiveWhenGoalIsNoTMet() public {
        uint256 goalAmount = s_fundMe.getGoalAmount();
        address owner = s_fundMe.getOwner();

        vm.prank(owner);
        vm.expectRevert(
            abi.encodeWithSelector(
                FundMe__GoalAmountNotMet.selector,
                address(s_fundMe).balance,
                goalAmount
            )
        );

        s_fundMe.performUpkeep("");
    }

    function testRetrieveIfFundsAmountNotMet() public {
        address owner = s_fundMe.getOwner();
        uint256 goalAmount = s_fundMe.getGoalAmount();

        vm.prank(owner);
        vm.expectRevert(
            abi.encodeWithSelector(
                FundMe__GoalAmountNotMet.selector,
                address(s_fundMe).balance,
                goalAmount
            )
        );

        s_fundMe.performUpkeep("");
    }

    function testRetrieveTransferFails() public {
        address owner = s_fundMe.getOwner();
        uint256 fundedAmount = 1 ether;
        uint256 fundedAmountInUSD = s_fundMe.convertToUSD(fundedAmount);

        vm.expectEmit(true, true, false, false);

        emit FundMe__Funded(address(this), fundedAmountInUSD);

        s_fundMe.fund{value: fundedAmount}();

        RevertingOwner newOwner = new RevertingOwner();

        vm.prank(owner);
        s_fundMe.setOwner(address(newOwner));

        vm.prank(address(newOwner));
        vm.expectRevert(
            abi.encodeWithSelector(
                FundMe__RetreiveError.selector,
                address(s_fundMe).balance
            )
        );

        s_fundMe.performUpkeep("");
    }

    function testSuccessfulRetreival() public {
        address owner = s_fundMe.getOwner();
        uint256 fundedAmount = 1 ether;
        uint256 fundedAmountInUSD = s_fundMe.convertToUSD(fundedAmount);

        uint256 oldOwnerBalance = owner.balance;

        vm.expectEmit(true, true, false, false);

        emit FundMe__Funded(address(this), fundedAmountInUSD);

        s_fundMe.fund{value: fundedAmount}();

        vm.prank(owner);

        vm.expectEmit(true, false, false, false);

        emit FundMe__DonationsCollected(fundedAmount);

        s_fundMe.performUpkeep("");

        FundMe.Status status = s_fundMe.getStatus();

        assertEq(fundedAmount + oldOwnerBalance, owner.balance);
        assertEq(uint256(status), 2);
    }
}
