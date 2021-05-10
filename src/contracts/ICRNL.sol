pragma solidity ^0.8.0;

// Commit-reveal numeric lottery interface
interface ICRNL{
    function commit(uint256 commitHash_) external payable;
    function changeCommitHash(uint256 commitHash_) external; // changes hash(Ni+salt) without any fees
    function reveal(uint128 revealNum_, uint128 salt_) external;
    function countRewards() external; // finds winners and gives additional reward to caller
    function takeReward() external;

    // let new user know if he can became participant
    function isFreePlaces() external view returns(bool isFreePlaces_); 

    function isRewardCounted() external view returns(bool isRewardCounted_);
}

