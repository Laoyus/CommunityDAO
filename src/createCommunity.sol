// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./communityDAO.sol";

contract CreateCommunity {
    CommunityDAO public dao;

    struct Community {
        string name;
        string description;
        address creator;
        uint256 creationTime;
        uint256 treasury;
        mapping(address => bool) members;
        mapping(address => bool) pollCreators;
    }

    struct Poll {
        string question;
        string[] options;
        address[] recipients; // Added: Funding recipients
        uint256[] voteCounts;
        uint256 creationTime;
        uint256 endTime;
        bool isClosed;
        bool fundsDistributed; // Added: Track fund distribution
        uint256 totalVotes;
        uint256 totalFund; // Added: Total ETH allocated
    }

    uint256 public communityCount;
    mapping(uint256 => Community) public communities;
    mapping(uint256 => Poll[]) public communityPolls;
    mapping(uint256 => mapping(uint256 => mapping(address => bool)))
        public hasVoted;

    // Events (updated)
    event CommunityCreated(uint256 indexed id, string name, address creator);
    event PollCreated(
        uint256 indexed communityId,
        uint256 pollId,
        string question,
        uint256 totalFund
    );
    event VoteCast(
        uint256 indexed communityId,
        uint256 pollId,
        address voter,
        uint256 option,
        uint256 power
    );
    event PollClosed(
        uint256 indexed communityId,
        uint256 pollId,
        uint256 winningOption
    );
    event FundsDistributed(
        uint256 indexed communityId,
        uint256 pollId,
        address winner,
        uint256 amount
    );

    modifier checkMember(address _member) {
        (, , , , bool existing) = dao.getMemberStruct(_member);
        require(existing, "Please register first!");
        _;
    }

    modifier validPollOptions(
        string[] memory _options,
        address[] memory _recipients
    ) {
        require(_options.length >= 2, "Need at least 2 options");
        require(
            _options.length == _recipients.length,
            "Options/recipients mismatch"
        );
        _;
    }

    constructor(address _daoAddress) {
        dao = CommunityDAO(_daoAddress);
    }

    // Community functions (unchanged)
    function createCommunity(
        string memory _name,
        string memory _description
    ) public returns (uint256) {
        uint256 id = communityCount++;
        Community storage newCommunity = communities[id];

        newCommunity.name = _name;
        newCommunity.description = _description;
        newCommunity.creator = msg.sender;
        newCommunity.creationTime = block.timestamp;
        newCommunity.members[msg.sender] = true;
        newCommunity.pollCreators[msg.sender] = true;

        emit CommunityCreated(id, _name, msg.sender);
        return id;
    }

    function addCommunityMember(
        uint256 _communityId,
        address _member
    ) external checkMember(_member) {
        require(dao.balanceOf(_member) > 0, "Not a DAO member");
        communities[_communityId].members[_member] = true;
    }

    // Modified poll creation with funding
    function createPoll(
        uint256 _communityId,
        string memory _question,
        string[] memory _options,
        address[] memory _recipients,
        uint256 _duration,
        uint256 _totalFund
    ) external payable returns (uint256) {
        require(
            communities[_communityId].pollCreators[msg.sender],
            "Not a poll creator"
        );
        require(_options.length >= 2, "Need at least 2 options");
        require(
            _options.length == _recipients.length,
            "Options/recipients mismatch"
        );
        require(msg.value >= _totalFund, "Insufficient funds");
        require(_totalFund > 0, "Fund must be positive");

        communities[_communityId].treasury += msg.value;

        uint256 pollId = communityPolls[_communityId].length;
        Poll memory newPoll = Poll({
            question: _question,
            options: _options,
            recipients: _recipients,
            voteCounts: new uint256[](_options.length),
            creationTime: block.timestamp,
            endTime: block.timestamp + _duration,
            isClosed: false,
            fundsDistributed: false,
            totalVotes: 0,
            totalFund: _totalFund
        });

        communityPolls[_communityId].push(newPoll);
        emit PollCreated(_communityId, pollId, _question, _totalFund);
        return pollId;
    }

    // Voting function (unchanged)
    function vote(
        uint256 _communityId,
        uint256 _pollId,
        uint256 _option
    ) external {
        Community storage community = communities[_communityId];
        Poll storage poll = communityPolls[_communityId][_pollId];

        require(community.members[msg.sender], "Not a community member");
        require(!poll.isClosed, "Poll closed");
        require(block.timestamp <= poll.endTime, "Voting period ended");
        require(!hasVoted[_communityId][_pollId][msg.sender], "Already voted");
        require(_option < poll.options.length, "Invalid option");

        uint256 power = dao.getVotingPower(msg.sender);
        poll.voteCounts[_option] += power;
        poll.totalVotes += power;
        hasVoted[_communityId][_pollId][msg.sender] = true;

        emit VoteCast(_communityId, _pollId, msg.sender, _option, power);
    }

    // Enhanced closePoll with automatic funding
    function closePoll(uint256 _communityId, uint256 _pollId) external {
        Poll storage poll = communityPolls[_communityId][_pollId];
        Community storage community = communities[_communityId];

        require(
            communities[_communityId].pollCreators[msg.sender],
            "Not authorized"
        );
        require(!poll.isClosed, "Already closed");
        require(block.timestamp > poll.endTime, "Voting still active");

        poll.isClosed = true;
        uint256 winningOption = getWinningOption(_communityId, _pollId);

        // Distribute funds if available
        if (poll.totalFund > 0 && community.treasury >= poll.totalFund) {
            address winner = poll.recipients[winningOption];
            community.treasury -= poll.totalFund;
            (bool success, ) = winner.call{value: poll.totalFund}("");
            require(success, "Transfer failed");
            poll.fundsDistributed = true;
            emit FundsDistributed(
                _communityId,
                _pollId,
                winner,
                poll.totalFund
            );
        }

        emit PollClosed(_communityId, _pollId, winningOption);
    }

    // View functions (unchanged)
    function getWinningOption(
        uint256 _communityId,
        uint256 _pollId
    ) public view returns (uint256) {
        Poll storage poll = communityPolls[_communityId][_pollId];
        uint256 winningOption;
        uint256 maxVotes;

        for (uint256 i = 0; i < poll.options.length; i++) {
            if (poll.voteCounts[i] > maxVotes) {
                maxVotes = poll.voteCounts[i];
                winningOption = i;
            }
        }
        return winningOption;
    }

    function contributeToTreasury(uint256 _communityId) external payable {
        require(msg.value > 0, "Must send ETH");
        communities[_communityId].treasury += msg.value;
    }

    // Removed allocateFunds since distribution is now automatic
}
