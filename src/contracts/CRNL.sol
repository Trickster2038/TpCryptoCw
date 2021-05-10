pragma solidity ^0.8.0;

import "./ICRNL.sol";
import "./SafeMath.sol";

// Commit-reveal numeric lottery
contract CRNL is ICRNL {

    using SafeMath for uint;
    using SafeMath for uint128;

    uint128 public maxNum; // max size of Ni

    uint256 public betSize; // bet & different fees sizes
    uint256 public honorFee;
    uint256 public ownerFee;
    uint256 public counterFee;

    uint256 public maxParticipants; // max number of users

    uint public startTime;  // time params of different phases
    uint public durationCommitTime;
    uint public durationRevealTime;
    uint public durationRewardingTime;

    uint256 private _avgNum;    // 2/3 of real avg
    uint256 private _minDifference; // min(Ni-_avgNum)
    uint256 private _totalRevealsCount; // number of revealed users
    uint256 private _sumNum; // sum(Ni)
    uint256 private _totalParticipants; // count(Users)
    uint256 private _winnerStake; // reward size
    bool private _isRewardCounted; 
    address private _owner;
    uint256 public ownerRewardUnspent; // unspent owner fees
    bool public isDestructRewardOwner; // who gets destruct reward

    struct UserData {
        uint256 id;
        uint256 commitHash; // hash(Ni+salt)
        bool isCommited;
        uint128 revealNum; // Ni
        bool isRevealed;
        bool isTookReward; 
    }

    struct Reveal {
        uint128 revealNum;
        address user;
    }

    // id => Ni, userAddress
    mapping (uint256 => Reveal) private _reveals;
    
    mapping (address => UserData) private _users;

    constructor (uint128 maxNum_, bool isDestructRewardOwner_, 
    uint256 betSize_, uint256 honorFee_, uint256 ownerFee_, uint256 counterFee_,
    uint256 maxParticipants_, 
    uint startTime_, uint durationCommitTime_, uint durationRevealTime_, uint durationRewardingTime_) {
        _owner = msg.sender;
        isDestructRewardOwner = isDestructRewardOwner_; // who gets destruct reward
        maxNum = maxNum_;   
        
        // setting fees:
        betSize = betSize_;
        honorFee = honorFee_;
        ownerFee = ownerFee_;
        counterFee = counterFee_;

        maxParticipants = maxParticipants_; // max number of users

        // time params of different phases:
        startTime = startTime_; 
        durationCommitTime = durationCommitTime_;
        durationRevealTime = durationRevealTime_;
        durationRewardingTime = durationRewardingTime_;
    }

    // modifiers to control in which phase contrct is (by time):

    modifier commitPhase() {
        require(block.timestamp > startTime, "contract is not started");
        require(block.timestamp < (startTime.add(durationCommitTime)), "commit phase finished");
        _;
    }

    modifier revealPhase(){
        require(block.timestamp > (startTime.add(durationCommitTime)), "reveal phase is not started");
        require(block.timestamp < (startTime.add(durationCommitTime).add(durationRevealTime)), "reveal phase finished");
        _;
    }

    modifier rewardPhase(){
        require(block.timestamp > (startTime.add(durationCommitTime).add(durationRevealTime)), "reward phase is not started");
        _;
    }

    // after (startTime + ... + durationRewardingTime) contract can be deleted, 
    // user ETH goes to owner or destructor (depends on settings)
    modifier selfDestructPhase(){
        require(block.timestamp > startTime.add(durationCommitTime) 
                                            .add(durationRevealTime) 
                                            .add(durationRewardingTime), 
        "destruct phase is not started");
        _;
    }

    // buggy working with "commitPhase" modifier
    // let new user know if he can became participant
    function isFreePlaces() public override view returns(bool isFreePlaces_)
    {
        return (_totalParticipants < maxParticipants);
    }

    // shows if rewardCount() called already
    function isRewardCounted() public override view returns(bool isRewardCounted_){
        return _isRewardCounted;
    }

    /* 
        1) saves hash(Ni+salt)
        2) gets ETH = bet + fees[] from new user
    */
    function commit(uint256 commitHash_) public override payable
    commitPhase
    {
        require(!_users[msg.sender].isCommited, "already commited");
        require(_totalParticipants < maxParticipants, "max part-s limit overflow");
        require(msg.value >= betSize.add(honorFee).add(ownerFee).add(counterFee), "not enougth ETH");

        _totalParticipants++;
        _users[msg.sender].id = _totalParticipants;
        _users[msg.sender].commitHash = commitHash_;
        _users[msg.sender].isCommited = true;

        ownerRewardUnspent = ownerRewardUnspent.add(ownerFee);

        uint256 extra = msg.value.sub( betSize.add(honorFee).add(ownerFee).add(counterFee) );
        payable(msg.sender).transfer(extra);
    }

    // changes hash(Ni+salt) without any fees
    function changeCommitHash(uint256 commitHash_) public override 
    commitPhase
    {
        require(_users[msg.sender].isCommited, "not commited");
        _users[msg.sender].commitHash = commitHash_;
    }

    /* 
        1) gets reveal 
        2) checks commit_hash == hash(reveal+salt)
        3) returns honorFee if hashes equal
    */
    function reveal(uint128 revealNum_, uint128 salt_) public override
    revealPhase
    {
        require(_users[msg.sender].isCommited, "not commited");
        require(!_users[msg.sender].isRevealed, "already revealed"); 
        require(revealNum_ != 0, "0 is reserved"); // 0 is default value
        require(revealNum_ <= maxNum, "num limit overflow");
        uint256 revealNum256 = uint256(revealNum_);
        uint256 salt256 = uint256(salt_);
        
        // overflow-safe due to 128 => 256 transformations
        uint256 secret = uint256((1<<255) + (revealNum256<<128) + salt256);
        bytes memory secret_b = abi.encodePacked(secret);
        uint256 proof = uint256(sha256(secret_b));

        require(proof == _users[msg.sender].commitHash, "hash check fail");
        payable(msg.sender).transfer(honorFee);
        _users[msg.sender].isRevealed = true;
        _reveals[_users[msg.sender].id].user = msg.sender;
        _reveals[_users[msg.sender].id].revealNum = revealNum_;

        // is safe due to users limit
        _totalRevealsCount++;
        _sumNum = _sumNum.add(revealNum_);
    }

    /*
        1) counts min(Ni - avg) and num_of_winners;
        2) counts prize = bet * users_count / num_of_winners
        3) returns bet to msg.sender as reward for calling
        4) pays counterFees to msg.sender
    */
    function countRewards() public override
    rewardPhase
    {
        require(_users[msg.sender].isCommited, "not commited"); 
        require(_users[msg.sender].isRevealed, "not revealed"); // Necessary to exclude x/0
        require(!_isRewardCounted, "rewards already counted");

        _isRewardCounted = true;

        // safe due to 128 => 256
        _minDifference = uint256(maxNum) + 1;
        _avgNum = ( _sumNum.mul(2) ).div( _totalRevealsCount.mul(3) ); // = 2/3 AVG
        uint256 difference;
        uint256 i;
        uint256 countWinners = 1; // at least 1 must exist
        for (i = 1; i <= _totalParticipants; i++) {

            // difference = abs(avg - Ni)
            if(_reveals[i].revealNum > _avgNum){
                difference = _reveals[i].revealNum - _avgNum;
            } else {
                difference = _avgNum - _reveals[i].revealNum;
            }

            if(difference < _minDifference){
                _minDifference = difference;
                countWinners = 1;
            } else if(difference == _minDifference){
                countWinners = countWinners.add(1);
            }
        }
        
        payable(msg.sender).transfer(_totalParticipants.mul(counterFee)); // reward for calling
        _totalParticipants = _totalParticipants.sub(1); // we can't use his bet as part of fund
        payable(msg.sender).transfer(betSize); // returns bet as additional reward for calling

        // overflow-safe: = betSize*0 / 1 = 0 if only 1 user revealed
        _winnerStake = (betSize.mul(_totalParticipants)).div(countWinners); 
    }

    // if (userIsWinner && rewardIsCounted) gives user the prize
    function takeReward() public override
    rewardPhase
    {
        require(_users[msg.sender].isCommited, "not commited"); 
        require(_users[msg.sender].isRevealed, "not revealed"); // Necessary to exclude x/0
        require(!_users[msg.sender].isTookReward, "reward is already taken");
        require(_isRewardCounted, "reward not counted");

        uint256 difference;

        // difference = abs(_avgNum - Ni)
        if(_reveals[_users[msg.sender].id].revealNum > _avgNum){
            difference = _reveals[_users[msg.sender].id].revealNum .sub(_avgNum);
        } else {
            difference = _avgNum .sub(_reveals[_users[msg.sender].id].revealNum);
        }

        require(difference == _minDifference, "not winner");
        payable(msg.sender).transfer(_winnerStake);
        _users[msg.sender].isTookReward = true;
    }

    function changeOwner(address owner_) public {
        require(msg.sender == _owner, "only owner can transfer his rights");
        _owner = owner_;
    }

    // owner's fee transfer is independent from time
    function rewardOwner() public {
        payable(_owner).transfer(ownerRewardUnspent);
        ownerRewardUnspent = 0;
    }

    // allows to destruct contract after use
    // unspent ETH goes to owner or destructor (depends on settings)
    function destruct() public
    selfDestructPhase
    {
        if(isDestructRewardOwner){
            selfdestruct(payable(_owner));
        } else {
            selfdestruct(payable(msg.sender));
        }
    }
}