pragma solidity ^0.8.0;

// Commit-reveal numeric lottery interface
interface ICRNL{
    function commit(bytes32 commitHash_) external payable;
    function changeCommitHash(bytes32 commitHash_) external; // changes hash(Ni+salt) without any fees
    function reveal(uint128 revealNum_, uint128 salt_) external;
    function countRewards() external; // finds winners and gives additional reward to caller
    function takeReward() external;

    // let new user know if he can became participant
    function isFreePlaces() external view returns(bool isFreePlaces_); 

    function getPhaseId() external view returns(uint8 phaseId_);
    function getWinnerStake() external view returns(uint256  winnerStake_);
    function getAvg() external view returns(uint256  avg_);
}

