// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import {NetworkConfig} from "script/NetworkConfig.s.sol";
import {FundMe_TimeBased, FundMe_TimeBased__PerformUpkeepError} from "contracts/FundMe_TimeBased.sol";
import {FundMe, FundMe__RetreiveError, FundMe__FundRequirementNotMet, FundMe__Fallback} from "contracts/FundMe.sol";
import {RevertingOwner} from "test/RevertingOwner.sol";
import {Ownable__NotOwner} from "contracts/Ownable.sol";
import {console2} from "forge-std/console2.sol";
import {Test} from "forge-std/Test.sol";

contract FundMe_TimeBasedTest is Test {
    event FundMe__Funded(
        address indexed funderAddress,
        uint256 indexed fundedAmount
    );
    event FundMe__DonationsCollected(uint256 indexed amount);

    uint256 internal s_initialContractBalance;

    bytes32 internal constant NAME = "Time Based Fundation";
    bytes32 internal constant DESCRIPTION = "This is time based foundation";

    FundMe_TimeBased internal s_fundMe;
    NetworkConfig.Config internal s_networkConfig;

    function setUp() public {
        NetworkConfig config = new NetworkConfig();
        s_networkConfig = config.getConfig();

        vm.startBroadcast();
        s_fundMe = new FundMe_TimeBased(
            NAME,
            DESCRIPTION,
            3600,
            1, // USD
            s_networkConfig.priceFeedAddress
        );
        console.log("Contract address: %s", address(s_fundMe));
        console.log(
            "Contract balance after deployment: %s",
            address(s_fundMe).balance
        );
        vm.stopBroadcast();

        s_initialContractBalance = address(s_fundMe).balance;
    }

    function testInitialContracValues() public view {
        uint256 timeLimit = s_fundMe.getTimeLimit();
        uint256 timeStamp = s_fundMe.getTimeStamp();
        string memory storedName = s_fundMe.getName();
        string memory storedDescription = s_fundMe.getDescription();

        string memory name = string(abi.encodePacked(NAME));
        string memory description = string(abi.encodePacked(DESCRIPTION));

        assertEq(name, storedName);
        assertEq(description, storedDescription);
        assertEq(timeStamp, block.timestamp);
        assertEq(timeLimit, 3600);
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
        assertEq(
            address(s_fundMe).balance,
            fundedAmount + s_initialContractBalance
        );
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
        vm.expectRevert(
            abi.encodeWithSelector(Ownable__NotOwner.selector, address(this))
        );
        s_fundMe.setStatus(FundMe.Status.Closed);
    }

    function testFallbackFunction() public {
        bytes memory data = abi.encodeWithSignature("nonExistentFunction()");
        vm.expectRevert(
            abi.encodeWithSelector(FundMe__Fallback.selector, data)
        );
        (bool sent, ) = address(s_fundMe).call(data);
    }

    function testCheckUpkeepShouldFail() public view {
        bool upkeepNeeded = s_fundMe.checkUpkeep("");
        assertEq(upkeepNeeded, false);
    }

    function testCheckUpkeepShouldPass() public {
        uint256 timeLimit = s_fundMe.getTimeLimit();
        uint256 timeStamp = s_fundMe.getTimeStamp();

        vm.warp(timeStamp + timeLimit + 1);
        bool upkeepNeeded = s_fundMe.checkUpkeep("");
        assertEq(upkeepNeeded, true);
    }

    function testOnlyOnwerCanRetrieveFunds() public {
        vm.expectRevert(
            abi.encodeWithSelector(Ownable__NotOwner.selector, address(this))
        );
        s_fundMe.performUpkeep("");
    }

    function testRetrieveIfContractStatusIsClosed() public {
        console.log(
            "Contract balance before funding: %s",
            address(s_fundMe).balance
        );

        address owner = s_fundMe.getOwner();
        uint256 timeLimit = s_fundMe.getTimeLimit();
        uint256 timeStamp = s_fundMe.getTimeStamp();
        uint256 fundedAmount = 1 ether;

        s_fundMe.fund{value: fundedAmount}();

        assertEq(
            address(s_fundMe).balance,
            fundedAmount + s_initialContractBalance
        );

        uint256 newStatus = 1;

        vm.prank(owner);
        s_fundMe.setStatus(FundMe.Status(newStatus));

        vm.prank(owner);
        vm.expectRevert(
            abi.encodeWithSelector(
                FundMe_TimeBased__PerformUpkeepError.selector,
                block.timestamp,
                timeStamp,
                timeLimit,
                newStatus
            )
        );
        s_fundMe.performUpkeep("");
    }

    function testRetrieveIfContractStatusIsFinished() public {
        address owner = s_fundMe.getOwner();
        uint256 timeLimit = s_fundMe.getTimeLimit();
        uint256 timeStamp = s_fundMe.getTimeStamp();
        uint256 fundedAmount = 1 ether;

        s_fundMe.fund{value: fundedAmount}();

        assertEq(
            address(s_fundMe).balance,
            fundedAmount + s_initialContractBalance
        );

        uint256 newStatus = 2;

        vm.prank(owner);
        s_fundMe.setStatus(FundMe.Status(newStatus));

        vm.prank(owner);
        vm.expectRevert(
            abi.encodeWithSelector(
                FundMe_TimeBased__PerformUpkeepError.selector,
                block.timestamp,
                timeStamp,
                timeLimit,
                newStatus
            )
        );
        s_fundMe.performUpkeep("");
    }

    function testRetrieveIfTimeHasNotPassed() public {
        address owner = s_fundMe.getOwner();
        uint256 timeLimit = s_fundMe.getTimeLimit();
        uint256 timeStamp = s_fundMe.getTimeStamp();
        FundMe.Status status = s_fundMe.getStatus();

        uint256 fundedAmount = 1 ether;
        uint256 fundedAmountInUSD = s_fundMe.convertToUSD(fundedAmount);

        vm.expectEmit(true, true, false, false);

        emit FundMe__Funded(address(this), fundedAmountInUSD);

        s_fundMe.fund{value: fundedAmount}();

        vm.prank(owner);
        vm.warp(timeStamp + timeLimit - 1);
        vm.expectRevert(
            abi.encodeWithSelector(
                FundMe_TimeBased__PerformUpkeepError.selector,
                block.timestamp,
                timeStamp,
                timeLimit,
                uint256(status)
            )
        );
        s_fundMe.performUpkeep("");
    }

    function testRetrieveTransferFails() public {
        uint256 timeLimit = s_fundMe.getTimeLimit();
        uint256 timeStamp = s_fundMe.getTimeStamp();

        address owner = s_fundMe.getOwner();
        uint256 fundedAmount = 1 ether;
        uint256 fundedAmountInUSD = s_fundMe.convertToUSD(fundedAmount);
        uint256 initialContractBalanceInUSD = s_fundMe.convertToUSD(
            s_initialContractBalance
        );

        vm.expectEmit(true, true, false, false);

        emit FundMe__Funded(address(this), fundedAmountInUSD);

        s_fundMe.fund{value: fundedAmount}();

        RevertingOwner newOwner = new RevertingOwner();

        vm.prank(owner);
        vm.warp(timeStamp + timeLimit + 1);

        s_fundMe.setOwner(address(newOwner));

        vm.prank(address(newOwner));
        vm.expectRevert(
            abi.encodeWithSelector(
                FundMe__RetreiveError.selector,
                fundedAmountInUSD + initialContractBalanceInUSD
            )
        );

        s_fundMe.performUpkeep("");
    }

    function testSuccessfulRetreival() public {
        address owner = s_fundMe.getOwner();

        uint256 ownerOldBalance = owner.balance;

        uint256 timeLimit = s_fundMe.getTimeLimit();
        uint256 timeStamp = s_fundMe.getTimeStamp();

        uint256 fundedAmount = 1 ether;
        uint256 fundedAmountInUSD = s_fundMe.convertToUSD(fundedAmount);
        uint256 initialContractBalanceInUSD = s_fundMe.convertToUSD(
            s_initialContractBalance
        );

        s_fundMe.fund{value: fundedAmount}();

        assertEq(
            address(s_fundMe).balance,
            fundedAmount + s_initialContractBalance
        );

        vm.prank(owner);
        vm.warp(timeStamp + timeLimit + 1);

        vm.expectEmit(true, false, false, false);
        emit FundMe__DonationsCollected(
            fundedAmountInUSD + initialContractBalanceInUSD
        );

        s_fundMe.performUpkeep("");

        FundMe.Status status = s_fundMe.getStatus();

        assertEq(
            ownerOldBalance + fundedAmount + s_initialContractBalance,
            owner.balance
        );
        assertEq(uint256(status), 2);
    }
}
