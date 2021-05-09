pragma solidity ^0.8.0;

contract CRDL{
    // struct HashTest {
    //     uint256 n1;
    //     uint256 n2; 
    //     uint256 secret;
    //     bytes secret_b;
    //     uint256 hashval;
    // }

    // HashTest public hashstr;
    uint256 public betSize;
    uint256 public honorFee;
    uint256 public ownerFee;
    uint256 public maxParticipants;
    uint256 private totalBetsAmount;
    uint256 private totalParticipants;
    uint256 private winnerStake;
    bool private isAwardCounted;

    struct UserData {
        uint256 id;
        uint256 commitHash;
        bool isCommited;
        uint128 revealNum;
        // uint128 revealSalt;
        bool isRevealed;
        bool isWinner;
    }

    // id => bet
    mapping (uint256 => uint128) private _reveals;
    
    mapping (address => UserData) private _users;

    constructor () {
    }

    // function hashPair(uint128 n1_, uint128 n2_) public{
    //     hashstr.n1 = uint256(n1_);
    //     hashstr.n2 = uint256(n2_);
    //     hashstr.secret = uint256((1<<255) + (hashstr.n1<<128) + hashstr.n2);
    //     hashstr.secret_b = abi.encodePacked(hashstr.secret);
    //     hashstr.hashval = uint256(sha256(hashstr.secret_b));
    // }
}