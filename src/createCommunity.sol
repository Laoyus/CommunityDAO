//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./communityDAO.sol";

contract CreateCommunity is CommunityDAO {
    struct Community {
        string name;
        string description;
        address creator;
        uint256 creationTime;
        uint256 id;
        address[] members; // List of members in the community
        address[] pollCreators; // List of poll creators in the community
        Poll[] polls; // List of polls in the community
    }

    struct Poll {
        string question;
        string[] options;
        mapping(uint256 => uint256) votes; // optionId => vote count
        address creator;
        uint256 creationTime;
        uint256 id;
    }

    Community[] public communities;
    uint256 public communityCount = 1; // Start from 1 for easier indexing
    mapping(uint256 => address[]) public communityMembers;

    event CommunityCreated(
        uint256 indexed communityId,
        string name,
        string description,
        address indexed creator
    );
    event PollCreated(
        uint256 indexed communityId,
        uint256 indexed pollId,
        string question,
        address indexed creator
    );
    event VoteCast(
        uint256 indexed communityId,
        uint256 indexed pollId,
        uint256 optionId,
        address indexed voter
    );
    event PollClosed(
        uint256 indexed communityId,
        uint256 indexed pollId,
        address indexed creator
    );
    event MemberAddedToCommunity(
        uint256 indexed communityId,
        address indexed member
    );

    modifier onlyCreator(uint256 _communityId) {
        require(
            communities[_communityId].creator == msg.sender,
            "Not the community creator"
        );
        _;
    }

    function createCommunity(
        string memory _name,
        string memory _description
    ) public nftMintedOnly returns (uint256) {
        Community memory newCommunity = Community({
            name: _name,
            description: _description,
            creator: msg.sender,
            creationTime: block.timestamp,
            id: communityCount,
            members: new address[](0),
            pollCreators: new address[](0),
            polls: new Poll[](0)
        });

        communities.push(newCommunity);
        communityMembers[communityCount] = new address[](0);
        emit CommunityCreated(communityCount, _name, _description, msg.sender);

        communityCount++;
        emit CommunityCreated(
            communityCount - 1,
            _name,
            _description,
            msg.sender
        );
        return communityCount - 1;
    }

    function addMemberToCommunity(
        uint256 _communityId,
        address _member
    ) public {
        require(
            members[_member].memberAddress != address(0),
            "Member does not exist"
        );
        require(
            !isMemberInCommunity(_communityId, _member),
            "Member already in community"
        );

        communities[_communityId].members.push(_member);
        communityMembers[_communityId].push(_member);
        members[_member].communities.push(_communityId);

        emit MemberAddedToCommunity(_communityId, _member);
    }

    function isMemberInCommunity(
        uint256 _communityId,
        address _member
    ) public view returns (bool) {
        for (uint256 i = 0; i < communities[_communityId].members.length; i++) {
            if (communities[_communityId].members[i] == _member) {
                return true;
            }
        }
        return false;
    }
}
