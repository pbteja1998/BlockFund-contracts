pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * Multiplication with safety check
    */
    function Mul(uint256 a, uint256 b) pure internal returns (uint256) {
      uint256 c = a * b;
      //check result should not be other wise until a=0
      assert(a == 0 || c / a == b);
      return c;
    }

    /**
    * Division with safety check
    */
    function Div(uint256 a, uint256 b) pure internal returns (uint256) {
      // assert(b > 0); // Solidity automatically throws when dividing by 0
      uint256 c = a / b;
      // assert(a == b * c + a % b); // There is no case in which this doesn't hold
      return c;
    }

    /**
    * Subtraction with safety check
    */
    function Sub(uint256 a, uint256 b) pure internal returns (uint256) {
      //b must be greater that a as we need to store value in unsigned integer
      assert(b <= a);
      return a - b;
    }

    /**
    * Addition with safety check
    */
    function Add(uint256 a, uint256 b) pure internal returns (uint256) {
      uint256 c = a + b;
      //We need to check result greater than only one number for valid Addition
      //refer https://ethereum.stackexchange.com/a/15270/16048
      assert(c >= a);
      return c;
    }
}

/**
 * Contract "ERC20Basic"
 * Purpose: Defining ERC20 standard with basic functionality like - CheckBalance and Transfer including Transfer event
 */
contract ERC20Basic {

  //Give realtime totalSupply of  token
  uint256 public totalSupply;

  //Get  token balance for provided address
  function balanceOf(address who) view public returns (uint256);

  //Transfer  token to provided address
  function transfer(address _to, uint256 _value) public returns(bool ok);

  //Emit Transfer event outside of blockchain for every  token transfer
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
}

/**
 * Contract "ERC20"
 * Purpose: Defining ERC20 standard with more advanced functionality like - Authorize spender to transfer  token
 */
contract ERC20 is ERC20Basic {

  //Get  token amount that spender can spend from provided owner's account
  function allowance(address owner, address spender) public view returns (uint256);

  //Transfer initiated by spender
  function transferFrom(address _from, address _to, uint256 _value) public returns(bool ok);

  //Add spender to authrize for spending specified amount of  Token
  function approve(address _spender, uint256 _value) public returns(bool ok);

  //Emit event for any approval provided to spender
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract Token is ERC20 {

  using SafeMath for uint256;

  /* Public variables of the token */
  //To store name for token
  string public constant name = "$1";

  //To store symbol for token
  string public constant symbol = "$2";

  //To store decimal places for token
  uint8 public constant decimals = 18;

  //To store decimal version for token
  string public version = 'v1.0';

  //flag to indicate whether transfer of  Token is allowed or not
  bool public locked;

  //map to store  Token balance corresponding to address
  mapping(address => uint256) balances;

  //To store spender with allowed amount of  Token to spend corresponding to IAC Token holder's account
  mapping (address => mapping (address => uint256)) allowed;

  //To handle ERC20 short address attack
  modifier onlyPayloadSize(uint256 size) {
     require(msg.data.length >= size + 4);
     _;
  }

  // Lock transfer during Sale
  modifier onlyUnlocked() {
    require(!locked);
    _;
  }

  //Contructor to define  Token properties
  function Token() public {
    // lock the transfer function during Sale
    locked = true;

    //initial token supply is 0
    totalSupply = 0;
  }

  //Implementation for transferring  Token to provided address
  function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) public onlyUnlocked returns (bool){

    //Check provided  Token should not be 0
    if (_to != address(0) && _value >= 1) {
      //deduct  Token amount from transaction initiator
      balances[msg.sender] = balances[msg.sender].Sub(_value);
      //Add  Token to balace of target account
      balances[_to] = balances[_to].Add(_value);
      //Emit event for transferring  Token
      Transfer(msg.sender, _to, _value);
      return true;
    }
    else{
      return false;
    }
  }

  //Transfer initiated by spender
  function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) public onlyUnlocked returns (bool) {

    //Check provided  Token should not be 0
    if (_to != address(0) && _from != address(0)) {
      //Get amount of  Token for which spender is authorized
      var _allowance = allowed[_from][msg.sender];
      //Add amount of  Token in trarget account's balance
      balances[_to] = balances[_to].Add(_value);
      //Deduct  Token amount from _from account
      balances[_from] = balances[_from].Sub(_value);
      //Deduct Authorized amount for spender
      allowed[_from][msg.sender] = _allowance.Sub(_value);
      //Emit event for Transfer
      Transfer(_from, _to, _value);
      return true;
    }else{
      return false;
    }
  }

  //Get  Token balance for provided address
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

  //Add spender to authorize for spending specified amount of  Token
  function approve(address _spender, uint256 _value) public returns (bool) {
    require(_spender != address(0));
    //do not allow decimals
    uint256 tokenToApprove = _value;
    allowed[msg.sender][_spender] = tokenToApprove;
    //Emit event for approval provided to spender
    Approval(msg.sender, _spender, tokenToApprove);
    return true;
  }

  //Get  Token amount that spender can spend from provided owner's account
  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

/**
 * Contract "Crowdsale"
 * Purpose: Contract for crowdsale of  Token
 */
contract Crowdsale is Token {
    
    using SafeMath for uint256;

    //Record the timestamp when sale starts
    uint256 public startBlock;
    //No of days for which the complete crowdsale will run
    uint256 public constant durationCrowdSale = $3;
    //Record the timestamp when sale ends
    uint256 public endBlock;
    // Minimum amount of ether to receive
    uint256 public targetToAchieve = $5;
    // Total number of tokens in circulation
    uint256 public totalSupply;
    //creator account where all ethers should go
    address public creator;
    //To store total number of ETH received
    uint256 public ETHReceived;
    //number of tokens per ether
    uint256 public getPrice
    // Description of the project
    string public description = "$4";
    // Check if crowdsale is complete or not
    uint256 isCrowdsaleComplete;
    // Number of investors in the project 
    uint256 investorCount = 0;
    
    //Emit event on receiving ETH
    event ReceivedETH(address addr, uint value);
    //Emit event when tokens are transferred from company inventory
    event SuccessfullyTransferedFromCompanyInventory(address addr, uint value, bytes32 comment);
    //event to log token supplied
    event TokenSupplied(address indexed beneficiary, uint256 indexed tokens, uint256 value);
    //Emit event when any change happens in crowdsale state
    event StateChanged(bool changed);

    /**
     * @dev Constuctor of the contract
     *
     */
    function Crowdsale() public {
        creator = $5;
        getPrice = 1e18;
	startBlock = now;
	endBlock = now.Add(durationCrowdSale)
	isCrowdsaleComplete = false;
    }

    //Modifier to make sure transaction is happening during sale when it is not stopped
    modifier respectTimeFrame() {
      //check if requirest is made after time is up
      if(now > endBlock){
          //tokens cannot be bought after time is up
          revert();
      }
      _;
    }

    /**
     * @dev payable function to accept ether.
     *
     */
    function () public payable {
        createTokens(msg.sender);
    }

    /*
    * To create and assign  Tokens to transaction initiator
    */
    function createTokens(address beneficiary) internal stopInEmergency  respectTimeFrame {
        //Make sure sent Eth is not 0
        require(msg.value != 0);
        //Initially count without giving discount
        uint256 tokenToSend = (msg.value.Mul(getPrice))/1e18;
        //store ETHReceived
        ETHReceived = ETHReceived.Add(msg.value);
        //Emit event for contribution
        ReceivedETH(beneficiary,ETHReceived);
	if (balances[beneficiary] == 0)
	{
		investorCount++;
	}
        balances[beneficiary] = balances[beneficiary].Add(tokenToSend);
        TokenSupplied(beneficiary, tokenToSend, msg.value);
    }


    function lowerGoal(uint value) public onlyOwner
    {
	    assert (now > endBlock);
	    assert(!goalAchieved && isCrowdsaleComplete)
	    targetToAchieve = value*1e18; // value will be amount of ether    
    }

    function lowerCrowdsaleLimitVoting() public
    {
	    
    }

    /*
    * Finalize the crowdsale
    */
    function finalize() public onlyOwner {
	    assert(!isCrowdsaleComplete)
	    if(this.balance >= targetToAchieve)
	    {
		    goalAchieved = true;
		    isCrowdsaleComplete = false;
	    }
	    else
		    goalAchieved = false;
	    isCrowdsaleComplete = true;
    }

}

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
