pragma solidity ^0.8.0;

import "./CRNL.sol";
import "./SafeMath.sol";
import "./ICRNL.sol";
import "./liteCRNL.sol";
import "./ABC.sol";

contract FactoryCRNL {

    CRNL[] public addressesCRNL;
    event CreatedCRNL(CRNL exemplarCRNL);
    address private _owner;
    uint256 private _maxParticipants;

    constructor(){
        _owner = msg.sender;
    }

    function changeOwner(address owner_) public {
        require(msg.sender == _owner);
        _owner = owner_;
    }

    function CreateCRNL(uint128 maxNum_, bool isDestructRewardOwner_, 
    uint256 betSize_, uint256 honorFee_, uint256 ownerFee_, uint256 counterFee_,
    uint256 maxParticipants_, 
    uint startTime_, uint durationCommitTime_, 
    uint durationRevealTime_, uint durationRewardingTime_) public {
        ABC exemplarABC = new ABC(2);
        //liteCRNL exemplarCRNL = new liteCRNL(100, 100, 86400, 86400);
        //CRNL exemplarCRNL = new CRNL(100, 100, 86400, 86400);
        //require(!(maxParticipants_ > _maxParticipants));
        //CRNL exemplarCRNL = new CRNL(100, true, 100,100,10,10, 15, 86400, 86400, 86400, 84000);
        // addressesCRNL.push(exemplarCRNL);
        //emit CreatedCRNL(exemplarCRNL);
    }

    function getAddressesCRNL() public view returns(CRNL[] memory){
        return addressesCRNL;
    }
}