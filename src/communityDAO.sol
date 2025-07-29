//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CommunityDAO is ERC721 {
    uint256 private _tokenIds;

    struct Member {
        address memberAddress;
        uint256 contribution;
        uint256 profileNftId; // ID of the profile NFT
    }

    uint256 public constant TOKENS_PER_ETH = 1000; // Example conversion rate

    mapping(address => Member) public members;
    address[] public memberList;

    event MemberAdded(address indexed member, uint256 contribution);
    event ContributionUpdated(address indexed member, uint256 newContribution);
    event TokensPurchased(
        address indexed member,
        uint256 ethAmount,
        uint256 tokenAmount
    );

    modifier newMemberOnly() {
        require(
            members[msg.sender].memberAddress == address(0),
            "Already a member"
        );
        _;
    }

    constructor() ERC721("CommunityProfile", "CPROF") {}

    modifier existingMemberOnly() {
        require(
            members[msg.sender].memberAddress != address(0),
            "Not a member"
        );
        _;
    }

    modifier nftMintedOnly() {
        require(
            members[msg.sender].profileNftId != 0,
            "Profile NFT not minted"
        );
        _;
    }

    function payEth(uint256 _value) private returns (uint256) {
        uint256 tokenAmount = _value * TOKENS_PER_ETH;

        // Mint new tokens to the buyer
        _mint(msg.sender, tokenAmount);

        // Update member contribution
        return tokenAmount;
    }

    function mintProfileNFT() external newMemberOnly returns (uint256) {
        require(
            members[msg.sender].profileNftId == 0,
            "Profile NFT already minted"
        );

        uint256 newTokenId = _tokenIds;
        _tokenIds++;

        _safeMint(msg.sender, newTokenId);
        members[msg.sender].profileNftId = newTokenId;

        return newTokenId;
    }

    // Optional: Override transfer functions to make NFT soulbound (non-transferable)
    // function _beforeTokenTransfer(
    //     address from,
    //     address to,
    //     uint256 tokenId,
    //     uint256 batchSize
    // ) internal virtual  {
    //     require(from == address(0) || to == address(0), "Token is soulbound");
    //     super._beforeTokenTransfer(from, to, tokenId, batchSize);
    // }

    function addMember() external payable nftMintedOnly returns (uint256) {
        require(msg.value > 0, "Must send ETH to purchase tokens");

        uint256 tokenAmount = msg.value * TOKENS_PER_ETH;

        // Mint new tokens to the buyer
        _mint(msg.sender, tokenAmount);

        // Update member contribution
        members[msg.sender].contribution += tokenAmount;
        members[msg.sender].memberAddress = msg.sender;

        emit MemberAdded(msg.sender, tokenAmount);
        return tokenAmount;
    }

    function updateContribution(
        address _member
    ) external payable existingMemberOnly returns (uint256) {
        require(msg.value > 0, "Must send ETH");
        members[_member].contribution += payEth(msg.value);

        emit ContributionUpdated(_member, members[_member].contribution);
        return members[_member].contribution;
    }

    function getMember(address _member) external view returns (Member memory) {
        require(
            members[_member].memberAddress != address(0),
            "Member does not exist"
        );
        return members[_member];
    }

    function getProfileNFT(address _member) external view returns (uint256) {
        require(
            members[_member].memberAddress != address(0),
            "Member does not exist"
        );
        require(members[_member].profileNftId != 0, "No profile NFT minted");
        return members[_member].profileNftId;
    }
}
