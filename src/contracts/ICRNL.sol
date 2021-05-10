pragma solidity ^0.8.0;

interface ICRNL{
    function commit(uint256 commitHash_) external payable;
    function changeCommitHash(uint256 commitHash_) external;
    function reveal(uint128 revealNum_, uint128 salt_) external;
    function countRewards() external;
    function takeReward() external;
    function isFreePlaces() external view returns(bool isFreePlaces_);
    function isRewardCounted() external view returns(bool isRewardCounted_);
}

