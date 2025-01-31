// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {OurToken} from "../src/OurToken.sol";
import {DeployOurToken} from "../script/DeployOurToken.s.sol";

contract OurTokenTest is Test {
    OurToken public ourToken;
    DeployOurToken public deployer;

    address bob = makeAddr("bob");
    address alice = makeAddr("alice");
    address carol = makeAddr("carol");

    uint256 public constant STARTING_BALANCE = 100 ether;

    // transfer() automaticalls sets the from address to the sender.
    // transferFrom() requires the from address to be set manually.

    function setUp() public {
        deployer = new DeployOurToken();
        ourToken = deployer.run();

        vm.prank(msg.sender); // The owner of the token should be the deployer.
        ourToken.transfer(bob, STARTING_BALANCE);
    }

    /* TESTS */

    // Test Bob's balance after initialization
    function testBobBalance() public view {
        assertEq(STARTING_BALANCE, ourToken.balanceOf(bob));
    }

    // Test allowances and transferFrom
    function testAllowancesWorks() public {
        // Authorize permission and set allowance
        // Authorized transfer .abi

        uint256 initialAllowance = 100;
        uint256 transferAmount = 20;

        // Bob approves alice to spend some amount of his token.
        vm.prank(bob);
        ourToken.approve(alice, initialAllowance);

        assertEq(ourToken.allowance(bob, alice), initialAllowance); // Check allowance

        // Alice transfers some amount of Bob's token to herself.
        vm.prank(alice);
        ourToken.transferFrom(bob, alice, transferAmount);

        assertEq((STARTING_BALANCE - transferAmount), ourToken.balanceOf(bob));
        assertEq(transferAmount, ourToken.balanceOf(alice));
    }

    // Test transfer between accounts
    function testTransfers() public {
        uint256 transferAmount = 50 ether;

        // Bob transfers tokens to Alice
        vm.prank(bob);
        ourToken.transfer(alice, transferAmount);

        assertEq(ourToken.balanceOf(bob), STARTING_BALANCE - transferAmount);
        assertEq(ourToken.balanceOf(alice), transferAmount);
    }

    // Test that transfer fails if sender has insufficient balance
    function testTransferRevertsIfInsufficientBalance() public {
        uint256 transferAmount = STARTING_BALANCE + 1 ether; // More than Bob's balance

        vm.prank(bob);
        vm.expectRevert(
            abi.encodeWithSignature(
                "ERC20InsufficientBalance(address,uint256,uint256)", bob, STARTING_BALANCE, transferAmount
            )
        );
        ourToken.transfer(alice, transferAmount);
    }

    // Test approve and allowance functionality
    function testApprove() public {
        uint256 allowanceAmount = 100 ether;

        // Bob approves Alice to spend tokens on his behalf
        vm.prank(bob);
        ourToken.approve(alice, allowanceAmount);

        assertEq(ourToken.allowance(bob, alice), allowanceAmount);
    }

    // Test that approve can overwrite an existing allowance
    function testApproveOverwritesExistingAllowance() public {
        uint256 initialAllowance = 50 ether;
        uint256 newAllowance = 100 ether;

        // Bob approves Alice
        vm.prank(bob);
        ourToken.approve(alice, initialAllowance);
        assertEq(ourToken.allowance(bob, alice), initialAllowance);

        // Bob updates Alice's allowance
        vm.prank(bob);
        ourToken.approve(alice, newAllowance);
        assertEq(ourToken.allowance(bob, alice), newAllowance);
    }

    function testTransferFrom() public {
        uint256 initialAllowance = 100;
        uint256 transferAmount = 20;

        // Bob approves Alice
        vm.prank(bob);
        ourToken.approve(alice, initialAllowance);

        // Alice transfers
        vm.prank(alice);
        ourToken.transferFrom(bob, alice, transferAmount);

        assertEq(ourToken.balanceOf(bob), STARTING_BALANCE - transferAmount);
        assertEq(ourToken.balanceOf(alice), transferAmount);
    }

    // Test transferFrom reverts if not enough allowance
    function testTransferFromRevertsIfNotEnoughAllowance() public {
        uint256 initialAllowance = 50 ether;
        uint256 transferAmount = 60 ether; // More than allowance

        // Bob approves Alice
        vm.prank(bob);
        ourToken.approve(alice, initialAllowance);

        // Alice tries to transfer more than allowance
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSignature(
                "ERC20InsufficientAllowance(address,uint256,uint256)", alice, initialAllowance, transferAmount
            )
        );
        ourToken.transferFrom(bob, alice, transferAmount);
    }

    // Test that total supply is consistent
    function testTotalSupplyConsistency() public view {
        uint256 totalSupply = ourToken.totalSupply();
        uint256 totalBalances = ourToken.balanceOf(msg.sender) + ourToken.balanceOf(bob) + ourToken.balanceOf(alice)
            + ourToken.balanceOf(carol);

        assertEq(totalSupply, totalBalances);
    }

    // Test that approve emits an Approval event
    // function testApproveEmitsEvent() public {
    //     uint256 allowanceAmount = 100 ether;

    //     vm.prank(bob);
    //     vm.expectEmit(true, true, false, true);
    //     emit Approval(bob, alice, allowanceAmount);
    //     ourToken.approve(alice, allowanceAmount);
    // }

    // Test transfer emits a Transfer event
    // function testTransferEmitsEvent() public {
    //     uint256 transferAmount = 50 ether;

    //     vm.prank(bob);
    //     vm.expectEmit(true, true, false, true);
    //     emit Transfer(bob, alice, transferAmount);
    //     ourToken.transfer(alice, transferAmount);
    // }

    // Test transferFrom emits a Transfer event
    // function testTransferFromEmitsEvent() public {
    //     uint256 initialAllowance = 100 ether;
    //     uint256 transferAmount = 20 ether;

    //     // Bob approves Alice
    //     vm.prank(bob);
    //     ourToken.approve(alice, initialAllowance);

    //     // Alice transfers tokens
    //     vm.prank(alice);
    //     vm.expectEmit(true, true, false, true);
    //     emit Transfer(bob, alice, transferAmount);
    //     ourToken.transferFrom(bob, alice, transferAmount);
    // }

    // Test balance consistency when transferring small amounts
    function testSmallTransfers() public {
        uint256 smallTransfer = 1 ether;

        // Bob transfers a small amount to Alice
        vm.prank(bob);
        ourToken.transfer(alice, smallTransfer);

        assertEq(ourToken.balanceOf(bob), STARTING_BALANCE - smallTransfer);
        assertEq(ourToken.balanceOf(alice), smallTransfer);
    }
}
