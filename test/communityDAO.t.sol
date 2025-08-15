// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {CommunityDAO} from "../src/communityDAO.sol";
import {CreateCommunity} from "../src/createCommunity.sol";

contract BaseSetup is Test {
    CommunityDAO public dao;
    CreateCommunity public createCommunity;

    address public admin = makeAddr("admin");
    address public member1 = makeAddr("member1");
    address public member2 = makeAddr("member2");
    address public nonMember = makeAddr("nonMember");

    function setUp() public virtual {
        dao = new CommunityDAO();
        createCommunity = new CreateCommunity(address(dao));

        // Fund test accounts
        vm.deal(admin, 10 ether);
        vm.deal(member1, 10 ether);
        vm.deal(member2, 10 ether);
        vm.deal(nonMember, 10 ether);
    }

    function _registerMember(address who, uint256 ethAmount) internal {
        vm.prank(who);
        dao.registerMember{value: ethAmount}();
    }
}

// ============ CommunityDAO Tests ============
contract CommunityDAOTests is BaseSetup {
    function test_MemberRegistration() public {
        vm.prank(member1);
        uint256 nftId = dao.registerMember{value: 1 ether}();

        assertEq(dao.balanceOf(member1), 1);
        assertEq(dao.ownerOf(nftId), member1);
        assertEq(dao.getVotingPower(member1), 1000 * 1e18);
    }
}

// ============ CreateCommunity Tests ============
contract CreateCommunityTests is BaseSetup {
    uint256 public communityId;

    function setUp() public override {
        super.setUp();

        // Register members
        _registerMember(admin, 1 ether);
        _registerMember(member1, 1 ether);
        _registerMember(member2, 2 ether);

        // Create a community
        vm.prank(admin);
        communityId = createCommunity.createCommunity(
            "Web3 Devs",
            "Solidity developers community"
        );
    }

    function test_CreatePollWithFunding() public {
        string[] memory options = new string[](2);
        options[0] = "Fund Project A";
        options[1] = "Fund Project B";

        address[] memory recipients = new address[](2);
        recipients[0] = member1;
        recipients[1] = member2;

        vm.prank(admin);
        uint256 pollId = createCommunity.createPoll{value: 5 ether}(
            communityId,
            "Allocate funds",
            options,
            recipients,
            3 days,
            5 ether
        );

        // Verify poll creation
        (string memory question, , , , , , uint256 totalFund) = createCommunity
            .communityPolls(communityId, pollId);
        assertEq(question, "Allocate funds");
        assertEq(totalFund, 5 ether);
    }

    function test_FullVotingWorkflow() public {
        // Setup poll
        string[] memory options = new string[](2);
        options[0] = "Option 1";
        options[1] = "Option 2";

        address[] memory recipients = new address[](2);
        recipients[0] = member1;
        recipients[1] = member2;

        vm.prank(admin);
        uint256 pollId = createCommunity.createPoll{value: 3 ether}(
            communityId,
            "Funding Vote",
            options,
            recipients,
            1 days,
            3 ether
        );

        // Add members to community
        vm.prank(admin);
        createCommunity.addCommunityMember(communityId, member1);

        vm.prank(admin);
        createCommunity.addCommunityMember(communityId, member2);

        // Member1 votes once
        vm.prank(member1);
        createCommunity.vote(communityId, pollId, 0);

        // Member2 votes once
        vm.prank(member2);
        createCommunity.vote(communityId, pollId, 1);

        // Close poll
        vm.warp(block.timestamp + 2 days);
        vm.prank(admin);
        createCommunity.closePoll(communityId, pollId);

        // Verify results
        uint256 winningOption = createCommunity.getWinningOption(
            communityId,
            pollId
        );
        assertEq(winningOption, 1); // Option 2 should win
    }

    function test_NonMemberCannotVote() public {
        // First create a poll
        string[] memory options = new string[](2);
        options[0] = "Option 1";
        options[1] = "Option 2";

        address[] memory recipients = new address[](2);
        recipients[0] = member1;
        recipients[1] = member2;

        vm.prank(admin);
        uint256 pollId = createCommunity.createPoll{value: 1 ether}(
            communityId,
            "Test Vote",
            options,
            recipients,
            1 days,
            1 ether
        );

        // Now test non-member voting
        vm.prank(nonMember);
        vm.expectRevert("Not a community member");
        createCommunity.vote(communityId, pollId, 0);
    }
}

// ============ Edge Cases ============
contract EdgeCaseTests is BaseSetup {
    function test_CannotCreatePollWithoutFunding() public {
        _registerMember(admin, 1 ether);
        vm.prank(admin);
        uint256 communityId = createCommunity.createCommunity("Test", "");

        string[] memory options = new string[](2);
        options[0] = "Option A";
        options[1] = "Option B";

        address[] memory recipients = new address[](2);
        recipients[0] = admin;
        recipients[1] = admin;

        vm.prank(admin);
        vm.expectRevert("Insufficient funds");
        createCommunity.createPoll{value: 0.5 ether}(
            communityId,
            "Underfunded",
            options,
            recipients,
            1 days,
            1 ether
        );
    }
}
