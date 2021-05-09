pragma solidity ^0.8.0;

interface ICRNL{
    function commit(uint256 commitHash_) external payable;
    function changeCommitHash(uint256 commitHash_) external;
    function reveal(uint128 revealNum_, uint128 salt_) external payable;
    function countRewards() external payable;
    function takeReward() external payable;

    //function uncommit() external payable;
    // optional:
    // changeOwner()
    // returnBet() ???
    // USE SAFEMATH!!!
}