pragma solidity ^0.8.0;

import "./ICRNL.sol";

contract CRNL is ICRNL {

    uint128 public maxNum;

    uint256 public betSize;
    uint256 public honorFee;
    uint256 public ownerFee;
    uint256 public counterFee;

    uint256 public maxParticipants;

    uint public startTime;
    uint public durationCommitTime;
    uint public durationRevealTime;
    uint public durationRewardingTime;

    uint256 private _avgNum;    // 2/3 of avg
    uint256 private _minDifference;
    //uint256 private _totalRevealsCount;
    //uint256 private _totalBetsAmount;
    uint256 private _sumNum;
    uint256 private _totalParticipants;
    uint256 private _winnerStake;
    bool private _isAwardCounted;
    address private _owner;
    uint256 public ownerRewardUnspent;
    bool public isDistructRewardOwner;

    struct UserData {
        uint256 id;
        uint256 commitHash;
        bool isCommited;
        uint128 revealNum;
        bool isRevealed;
        bool isTookReward;
        // bool isWinner;
    }

    struct Reveal {
        uint128 revealNum;
        address user;
    }

    // id => num, user
    mapping (uint256 => Reveal) private _reveals;
    
    mapping (address => UserData) private _users;

    constructor (uint128 maxNum_, bool isDistructRewardOwner_, uint256 betSize_, uint256 honorFee_, uint256 ownerFee_, 
    uint256 counterFee_,uint256 maxParticipants_, uint startTime_, uint durationCommitTime_,
    uint durationRevealTime_, uint durationRewardingTime_) {
        _owner = msg.sender;
        isDistructRewardOwner = isDistructRewardOwner_;
        maxNum = maxNum_;
        betSize = betSize_;
        honorFee = honorFee_;
        ownerFee = ownerFee_;
        counterFee = counterFee_;
        maxParticipants = maxParticipants_;
        startTime = startTime_;
        durationCommitTime = durationCommitTime_;
        durationRevealTime = durationRevealTime_;
        durationRewardingTime = durationRewardingTime_;
    }

    modifier commitPhase() {
        require(block.timestamp > startTime, "contract is not started");
        require(block.timestamp < (startTime + durationCommitTime), "commit phase finished");
        _;
    }

    modifier revealPhase(){
        require(block.timestamp > (startTime + durationCommitTime), "reveal phase is not started");
        require(block.timestamp < (startTime + durationCommitTime + durationRevealTime), "reveal phase is finished");
        _;
    }

    modifier rewardPhase(){
        require(block.timestamp > (startTime + durationCommitTime + durationRevealTime), "reward phase is not started");
        //require(block.timestamp < (startTime + durationCommitTime + durationRevealTime + durationRewardingTime));
        _;
    }

    modifier selfDistructPhase(){
        require(block.timestamp > (startTime + durationCommitTime + durationRevealTime + durationRewardingTime));
        _;
    }

    function totalParticipants() public override view returns(uint256 participants_) {
        return _totalParticipants;
    }

    function commit(uint256 commitHash_) public override payable
    commitPhase
    {
        require(!_users[msg.sender].isCommited, "already commited");
        require(_totalParticipants < maxParticipants, "max part-s limit");
        require(msg.value >= betSize + honorFee + ownerFee + counterFee, "not enougth ETH");

        _totalParticipants++;
        _users[msg.sender].id = _totalParticipants;
        _users[msg.sender].commitHash = commitHash_;
        _users[msg.sender].isCommited = true;

        ownerRewardUnspent += ownerFee;

        uint256 extra = msg.value - (betSize + honorFee + ownerFee + counterFee);
        payable(msg.sender).transfer(extra);
    }

    function changeCommitHash(uint256 commitHash_) public override 
    commitPhase
    {
        require(_users[msg.sender].isCommited, "not commited");
        _users[msg.sender].commitHash = commitHash_;
    }

    function reveal(uint128 revealNum_, uint128 salt_) public override
    revealPhase
    {
        require(_users[msg.sender].isCommited, "not commited");
        require(!_users[msg.sender].isRevealed, "already revealed"); // is it necessary?
        require(revealNum_ != 0, "0 is reserved"); // WARNING!!!
        require(revealNum_ <= maxNum, "num limit overflow");
        uint256 revealNum256 = uint256(revealNum_);
        uint256 salt256 = uint256(salt_);

        uint256 secret = uint256((1<<255) + (revealNum256<<128) + salt256);
        bytes memory secret_b = abi.encodePacked(secret);
        uint256 proof = uint256(sha256(secret_b));

        require(proof == _users[msg.sender].commitHash, "hash check fail");
        payable(msg.sender).transfer(honorFee);
        _users[msg.sender].isRevealed = true;
        _reveals[_users[msg.sender].id].user = msg.sender;
        _reveals[_users[msg.sender].id].revealNum = revealNum_;

        //_totalRevealsCount++;
        _sumNum += revealNum_;
    }

    function countRewards() public override
    rewardPhase
    {
        require(_users[msg.sender].isCommited, "not commited"); // necessary if cond2?
        require(_users[msg.sender].isRevealed, "not revealed"); // Necessary to exclude x/0
        require(!_isAwardCounted, "rewards already counted");

        _isAwardCounted = true;

        _minDifference = maxNum + 1;
        _avgNum = (_sumNum * 2) / (_totalParticipants * 3);
        uint256 difference;
        uint256 i;
        uint256 countWinners = 0;
        for (i = 1; i <= _totalParticipants; i++) {
            if(_reveals[i].revealNum > _avgNum){
                difference = _reveals[i].revealNum - _avgNum;
            } else {
                difference = _avgNum - _reveals[i].revealNum;
            }

            if(difference < _minDifference){
                _minDifference = difference;
                countWinners = 1;
            } else if(difference == _minDifference){
                countWinners++;
            }
        }
        
        payable(msg.sender).transfer(_totalParticipants * counterFee); // reward for calling
        _totalParticipants--;
        payable(msg.sender).transfer(betSize); // reward for calling
        _winnerStake = (betSize * _totalParticipants) / countWinners; // garants not x/0?
    }

    function takeReward() public override
    rewardPhase
    {
        require(_users[msg.sender].isCommited, "not commited"); // necessary?
        require(_users[msg.sender].isRevealed, "not revealed"); // Necessary to exclude x/0
        require(!_users[msg.sender].isTookReward, "reward is already taken");
        require(_isAwardCounted, "reward not counted");

        uint256 difference;
        if(_reveals[_users[msg.sender].id].revealNum > _avgNum){
            difference = _reveals[_users[msg.sender].id].revealNum - _avgNum;
        } else {
            difference = _avgNum - _reveals[_users[msg.sender].id].revealNum;
        }

        require(difference == _minDifference, "not winner");
        // require(_winnerStake > 0, "winner stake = 0");
        payable(msg.sender).transfer(_winnerStake);
        _users[msg.sender].isTookReward = true;
    }

    function changeOwner(address owner_) public {
        require(msg.sender == _owner);
        _owner = owner_;
    }

    function rewardOwner() public {
        payable(_owner).transfer(ownerRewardUnspent);
        ownerRewardUnspent = 0;
    }

    function distruct() public
    selfDistructPhase
    {
        if(isDistructRewardOwner){
            selfdestruct(payable(_owner));
        } else {
            selfdestruct(payable(msg.sender));
        }
    }
}