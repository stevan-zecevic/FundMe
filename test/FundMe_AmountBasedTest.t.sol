// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import {FundMe_AmountBased, FundMe_AmountBased__PerformUpkeepError} from "contracts/FundMe_AmountBased.sol";
import {
    FundMe,
    FundMe__GoalAmountNotMet,
    FundMe__RetreiveError,
    FundMe__FundRequirementNotMet,
    FundMe__Fallback
} from "contracts/FundMe.sol";
import {Ownable, Ownable__NotOwner} from "contracts/Ownable.sol";
import {MockV3Aggregator} from "test/mock/MockV3Aggregator.t.sol";
import {NetworkConfig} from "script/NetworkConfig.s.sol";
import {RevertingOwner} from "test/RevertingOwner.sol";
import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";

contract FundMe_AmountBasedTest is Test {
    event FundMe__Funded(address indexed funderAddress, uint256 indexed fundedAmount);
    event FundMe__DonationsCollected(uint256 indexed amount);

    uint256 constant GOAL_AMOUNT = 100; // 100 USD
    uint256 constant MINIMUM_FUND = 1; // 1 USD

    uint256 internal s_initialContractBalance;

    bytes32 internal constant NAME = "Amount Based Fundation";
    bytes32 internal DESCRIPTION = "This is amount based foundation";

    FundMe_AmountBased s_fundMe;
    NetworkConfig.Config internal s_networkConfig;

    function setUp() external {
        NetworkConfig networkConfig = new NetworkConfig();
        s_networkConfig = networkConfig.getConfig();

        vm.startBroadcast();
        s_fundMe =
            new FundMe_AmountBased(NAME, DESCRIPTION, GOAL_AMOUNT, MINIMUM_FUND, s_networkConfig.priceFeedAddress);
        vm.stopBroadcast();

        s_initialContractBalance = address(s_fundMe).balance;
    }

    function testInitialContractValues() public view {
        uint256 goalAmount = s_fundMe.getGoalAmount();
        address owner = s_fundMe.getOwner();
        uint256 numberOfFunders = s_fundMe.getNumberOfFunders();
        uint256 firstFunderAmount = s_fundMe.getFundersAmount(msg.sender);
        FundMe.Status fundMeStatus = s_fundMe.getStatus();
        uint256 minimumFund = s_fundMe.getMinimumFund();
        string memory storedName = s_fundMe.getName();
        string memory storedDescription = s_fundMe.getDescription();

        string memory name = string(abi.encodePacked(NAME));
        string memory description = string(abi.encodePacked(DESCRIPTION));

        assertEq(name, storedName);
        assertEq(description, storedDescription);
        assertEq(goalAmount, GOAL_AMOUNT);
        assertEq(owner, msg.sender);
        assertEq(numberOfFunders, 0);
        assertEq(firstFunderAmount, 0);
        assertEq(uint256(fundMeStatus), 0);
        assertEq(minimumFund, MINIMUM_FUND);
    }

    function testFundZeroAmount() public {
        FundMe.Status status = s_fundMe.getStatus();

        vm.expectRevert(
            abi.encodeWithSelector(FundMe__FundRequirementNotMet.selector, address(this), uint256(status), 0, 0)
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
        assertEq(address(s_fundMe).balance, fundedAmount + s_initialContractBalance);
    }

    function testSetingStatus() public {
        address owner = s_fundMe.getOwner();
        FundMe.Status currentStatus = s_fundMe.getStatus();

        vm.prank(owner);
        s_fundMe.setStatus(FundMe.Status.Closed);
        FundMe.Status newStatus = s_fundMe.getStatus();

        assertNotEq(uint256(currentStatus), uint256(newStatus));
        assertEq(uint256(newStatus), uint256(FundMe.Status.Closed));
    }

    function testSettingStatusNotOwner() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable__NotOwner.selector, address(this)));
        s_fundMe.setStatus(FundMe.Status.Closed);
    }

    function testFallbackFunction() public {
        bytes memory data = abi.encodeWithSignature("nonExistentFunction()");
        vm.expectRevert(abi.encodeWithSelector(FundMe__Fallback.selector, data));
        (bool sent,) = address(s_fundMe).call(data);
    }

    function testOnlyOnwerCanRetrieveFunds() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable__NotOwner.selector, address(this)));

        s_fundMe.performUpkeep("");
    }

    function testRetrieveIfContractStatusIsClosed() public {
        address owner = s_fundMe.getOwner();
        uint256 goalAmount = s_fundMe.getGoalAmount();
        uint256 fundedAmount = 1 ether;
        uint256 fundedAmountInUSD = s_fundMe.convertToUSD(fundedAmount);
        uint256 initialContractBalanceInUSD = s_fundMe.convertToUSD(s_initialContractBalance);

        s_fundMe.fund{value: fundedAmount}();

        assertEq(address(s_fundMe).balance, fundedAmount + s_initialContractBalance);

        uint256 newStatus = 1;

        vm.prank(owner);
        s_fundMe.setStatus(FundMe.Status(newStatus));

        vm.prank(owner);
        vm.expectRevert(
            abi.encodeWithSelector(
                FundMe_AmountBased__PerformUpkeepError.selector,
                newStatus,
                fundedAmountInUSD + initialContractBalanceInUSD,
                goalAmount
            )
        );
        s_fundMe.performUpkeep("");
    }

    function testRetrieveIfContractStatusIsFinished() public {
        address owner = s_fundMe.getOwner();
        uint256 goalAmount = s_fundMe.getGoalAmount();
        uint256 fundedAmount = 1 ether;
        uint256 fundedAmountInUSD = s_fundMe.convertToUSD(fundedAmount);
        uint256 initialContractBalanceInUSD = s_fundMe.convertToUSD(s_initialContractBalance);

        s_fundMe.fund{value: fundedAmount}();

        assertEq(address(s_fundMe).balance, fundedAmount + s_initialContractBalance);

        uint256 newStatus = 2;

        vm.prank(owner);
        s_fundMe.setStatus(FundMe.Status(newStatus));

        vm.prank(owner);
        vm.expectRevert(
            abi.encodeWithSelector(
                FundMe_AmountBased__PerformUpkeepError.selector,
                newStatus,
                fundedAmountInUSD + initialContractBalanceInUSD,
                goalAmount
            )
        );
        s_fundMe.performUpkeep("");
    }

    function testRetreiveWhenGoalIsNotMet() public {
        address owner = s_fundMe.getOwner();
        uint256 goalAmount = s_fundMe.getGoalAmount();
        uint256 contractBalance = address(s_fundMe).balance;
        uint256 contractBalanceInUSD = s_fundMe.convertToUSD(contractBalance);
        FundMe.Status status = s_fundMe.getStatus();

        vm.prank(owner);
        vm.expectRevert(
            abi.encodeWithSelector(
                FundMe_AmountBased__PerformUpkeepError.selector, uint256(status), contractBalanceInUSD, goalAmount
            )
        );

        s_fundMe.performUpkeep("");
    }

    function testRetrieveTransferFails() public {
        address owner = s_fundMe.getOwner();
        uint256 fundedAmount = 1 ether;
        uint256 fundedAmountInUSD = s_fundMe.convertToUSD(fundedAmount);
        uint256 initialContractBalanceInUSD = s_fundMe.convertToUSD(s_initialContractBalance);

        vm.expectEmit(true, true, false, false);

        emit FundMe__Funded(address(this), fundedAmountInUSD);

        s_fundMe.fund{value: fundedAmount}();

        RevertingOwner newOwner = new RevertingOwner();

        vm.prank(owner);
        s_fundMe.setOwner(address(newOwner));

        vm.prank(address(newOwner));
        vm.expectRevert(
            abi.encodeWithSelector(FundMe__RetreiveError.selector, fundedAmountInUSD + initialContractBalanceInUSD)
        );

        s_fundMe.performUpkeep("");
    }

    function testSuccessfulRetreival() public {
        address owner = s_fundMe.getOwner();
        uint256 fundedAmount = 1 ether;
        uint256 fundedAmountInUSD = s_fundMe.convertToUSD(fundedAmount);
        uint256 initialContractBalanceInUSD = s_fundMe.convertToUSD(s_initialContractBalance);

        uint256 oldOwnerBalance = owner.balance;

        vm.expectEmit(true, true, false, false);

        emit FundMe__Funded(address(this), fundedAmountInUSD);

        s_fundMe.fund{value: fundedAmount}();

        vm.prank(owner);

        vm.expectEmit(true, false, false, false);

        emit FundMe__DonationsCollected(fundedAmountInUSD + initialContractBalanceInUSD);

        s_fundMe.performUpkeep("");

        FundMe.Status status = s_fundMe.getStatus();

        assertEq(fundedAmount + oldOwnerBalance + s_initialContractBalance, owner.balance);
        assertEq(uint256(status), 2);
    }
}
