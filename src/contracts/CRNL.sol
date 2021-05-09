pragma solidity ^0.8.0;

import "./ICRNL.sol";

contract CRNL is ICRNL {

    // struct HashTest {
    //     uint256 n1;
    //     uint256 n2; 
    //     uint256 secret;
    //     bytes secret_b;
    //     uint256 hashval;
    // }
    // HashTest public hashstr;

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

    uint256 private _avgNum;
    uint256 private _minDifference;
    //uint256 private _totalRevealsCount;
    //uint256 private _totalBetsAmount;
    uint256 private _sumNum;
    uint256 private _totalParticipants;
    uint256 private _winnerStake;
    bool private _isAwardCounted;
    address private _owner;

    struct UserData {
        uint256 id;
        uint256 commitHash;
        bool isCommited;
        uint128 revealNum;
        // uint128 revealSalt;
        bool isRevealed;
        // bool isWinner;
    }

    struct Reveal {
        uint128 revealNum;
        address user;
    }

    // id => num, user
    mapping (uint256 => Reveal) private _reveals;

    // id => bet
    // mapping (uint256 => uint128) private _reveals;
    // id => user
    // mapping (uint256 => address) private _usersById;
    
    mapping (address => UserData) private _users;

    constructor (uint128 maxNum_, uint256 betSize_, uint256 honorFee_, uint256 ownerFee_, 
    uint256 counterFee_,uint256 maxParticipants_, uint startTime_, uint durationCommitTime_,
    uint durationRevealTime_, uint durationRewardingTime_) {
        _owner = msg.sender;
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
        require(!_isAwardCounted, "awards already counted");

        _isAwardCounted = true;

        _minDifference = maxNum + 1;
        _avgNum = _sumNum / _totalParticipants;
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
        require(_isAwardCounted, "award not counted");

        uint256 difference;
        if(_reveals[_users[msg.sender].id].revealNum > _avgNum){
            difference = _reveals[_users[msg.sender].id].revealNum - _avgNum;
        } else {
            difference = _avgNum - _reveals[_users[msg.sender].id].revealNum;
        }

        require(difference == _minDifference, "not winner");
        // require(_winnerStake > 0, "winner stake = 0");
        payable(msg.sender).transfer(_winnerStake);
    }

    // function hashPair(uint128 n1_, uint128 n2_) public{
    //     hashstr.n1 = uint256(n1_);
    //     hashstr.n2 = uint256(n2_);
    //     hashstr.secret = uint256((1<<255) + (hashstr.n1<<128) + hashstr.n2);
    //     hashstr.secret_b = abi.encodePacked(hashstr.secret);
    //     hashstr.hashval = uint256(sha256(hashstr.secret_b));
    // }

    // function hashCheck1(uint256 hash_) public view{
    //     require(hash_ == hashstr.hashval, "hash error");
    // }
}