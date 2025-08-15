// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract CommunityDAO is ERC721 {
    uint256 private _tokenIds;
    uint256 public constant TOKENS_PER_ETH = 1000;

    struct Member {
        address memberAddress;
        uint256 contribution; // ETH contributed
        uint256 profileNftId;
        uint256 votingPower;
        bool exists;
    }

    mapping(address => Member) public members;
    mapping(address => uint256) private _votingBalances;
    address[] public memberList;

    event MemberRegistered(address indexed member, uint256 nftId);
    event ContributionAdded(
        address indexed member,
        uint256 amount,
        uint256 votingPower
    );
    event VotingPowerUpdated(address indexed member, uint256 newVotingPower);

    constructor() ERC721("CommunityDAO Profile", "CDAONFT") {}

    // Makes NFTs soulbound (non-transferable)
    // function _beforeTokenTransfer(
    //     address from,
    //     address to,
    //     uint256 tokenId,
    //     uint256 batchSize
    // ) internal virtual {
    //     require(
    //         from == address(0) || to == address(0),
    //         "Soulbound NFT: Cannot transfer"
    //     );
    //     super._beforeTokenTransfer(from, to, tokenId, batchSize);
    // }

    function registerMember() external payable returns (uint256) {
        require(msg.value > 0, "Must contribute ETH to register");
        require(!members[msg.sender].exists, "Already registered");

        uint256 newTokenId = _tokenIds++;
        _safeMint(msg.sender, newTokenId);

        uint256 votingTokens = msg.value * TOKENS_PER_ETH;
        _votingBalances[msg.sender] = votingTokens;

        members[msg.sender] = Member({
            memberAddress: msg.sender,
            contribution: msg.value,
            profileNftId: newTokenId,
            votingPower: votingTokens,
            exists: true
        });
        memberList.push(msg.sender);

        emit MemberRegistered(msg.sender, newTokenId);
        emit ContributionAdded(msg.sender, msg.value, votingTokens);
        return newTokenId;
    }

    function addContribution() external payable {
        require(members[msg.sender].exists, "Not a member");
        require(msg.value > 0, "Must contribute ETH");

        uint256 votingTokens = msg.value * TOKENS_PER_ETH;
        _votingBalances[msg.sender] += votingTokens;

        members[msg.sender].contribution += msg.value;
        members[msg.sender].votingPower += votingTokens;

        emit ContributionAdded(msg.sender, msg.value, votingTokens);
    }

    function getVotingPower(address member) external view returns (uint256) {
        require(members[member].exists, "Not a member");
        return _votingBalances[member];
    }

    function totalMembers() external view returns (uint256) {
        return memberList.length;
    }

    function getMemberStruct(
        address _member
    )
        external
        view
        returns (
            address memberAddress,
            uint256 contribution,
            uint256 profileNftId,
            uint256 votingPower,
            bool exists
        )
    {
        Member storage member = members[_member];
        return (
            member.memberAddress,
            member.contribution,
            member.profileNftId,
            member.votingPower,
            member.exists
        );
    }
}
