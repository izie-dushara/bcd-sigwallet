/// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.28;

import {MultiSig} from "./MultiSig.sol";
import {Test} from "forge-std/Test.sol";

contract MultiSigTest is Test {
    MultiSig multiSig;
    address[] owners;

    address alice = address(0x1);
    address bob = address(0x2);
    address carol = address(0x3);

    address payable recipient = payable(address(0xBEEF));

    function setUp() public {
        owners.push(alice);
        owners.push(bob);
        owners.push(carol);

        multiSig = new MultiSig(owners, 2);

        vm.deal(address(this), 10 ether);
        (bool sent, ) = address(multiSig).call{value: 5 ether}("");
        require(sent, "funding failed");
    }

    function test_Deployment() public view {
        assertEq(multiSig.required(), 2);
        assertTrue(multiSig.isOwner(alice));
        assertTrue(multiSig.isOwner(bob));
        assertTrue(multiSig.isOwner(carol));
    }

    function test_SubmitAndExecuteTransaction() public {
        vm.prank(alice);
        multiSig.submit(recipient, 1 ether, "");

        vm.prank(alice);
        multiSig.approve(0);

        uint balanceBefore = recipient.balance;

        vm.prank(bob);
        multiSig.approve(0);

        vm.prank(carol);
        multiSig.approve(0);

        vm.prank(alice);
        multiSig.execute(0);

        assertEq(
            recipient.balance,
            balanceBefore + 1 ether,
            "recipient should have received 1 eth"
        );
    }

    function test_RevokeApproval() public {
        vm.prank(alice);
        multiSig.submit(recipient, 1 ether, "");

        vm.prank(alice);
        multiSig.approve(0);
        vm.prank(alice);
        multiSig.revoke(0);

        vm.prank(bob);
        multiSig.approve(0);

        vm.expectRevert();
        vm.prank(carol);
        multiSig.execute(0);
    }
}
