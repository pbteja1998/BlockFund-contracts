pragma solidity ^0.4.0;

contract Project {
    
    uint projectId;
    
    string projectName;
    
    uint projectTarget;
    
    uint fundRaised;
    
    bool projectActive = true;
    
    address public owner;
    
    uint public creationTime;

    // Modifiers can be used to change
    // the body of a function.
    // If this modifier is used, it will
    // prepend a check that only passes
    // if the function is called from
    // a certain address.
    modifier isOwner(){
        require(
            msg.sender == owner
            
        );_;
    }
    
    constructor(uint id) public {
        owner = msg.sender;
        // //creator = TokenCreator(msg.sender);
        // name = _name;
        projectId = id;
        fundRaised = 0;
        creationTime = now;
    }
    
    function setProject( string name) public{
    //   projectId = id;
       
       projectName = name;
       
    }
    function setTarget(uint target) public{
       projectTarget = target; 
    }
    
    
    function viewProjectTarget() public view returns(uint) {
        return projectTarget;
    } 
    
    function viewFundRaised() public view returns(uint) {
        return fundRaised;
    }
    
    function pay(uint amt) public{
        fundRaised = fundRaised + amt;
    }
    
    function endProject() public isOwner{
        projectActive= false;
    }
    function projectProposal(uint extraAmountNeeded) public{
        projectTarget = projectTarget + extraAmountNeeded;
    }
}
