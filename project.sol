pragma solidity ^0.4.0;

contract Project {
    
    uint public projectId;
    
    string public projectName;
    
    uint projectTarget;
    
    uint fundRaised;
    
    bool public projectActive;
    
    address public owner;
    
    uint public creationTime;
    
    modifier isOwner(){require(msg.sender == owner);_;}

    modifier isActive(){require(projectActive == true);_;}
    
    constructor(uint id , uint target) public {
        owner = msg.sender;
        // //creator = TokenCreator(msg.sender);
        // name = _name;
        projectId = id;
        fundRaised = 0;
        creationTime = now;
        projectTarget = target;
        projectActive = true;
    }
    
    function setProject( string name) public isOwner isActive{
       projectName = name;
       
    }
    
    function viewProjectTarget() public view returns(uint) {
        return projectTarget;
    } 
    
    function viewFundRaised() public view returns(uint) {
        return fundRaised;
    }
    
    function pay(uint amt) public isActive {
        fundRaised = fundRaised + amt;
    }
    
    function endProject() public isOwner isActive{
        projectActive= false;
    }
    function projectProposal(uint extraAmountNeeded) public isOwner isActive{
        projectTarget = projectTarget + extraAmountNeeded;
    }
}
