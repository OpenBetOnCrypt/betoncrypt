contract CrowdsaleICO is Ownable {
    
    using SafeMath for uint;
    
    enum State { Active, Refunding, Close }
    
    address public multisig;

    uint public restrictedPercent;

    address public restricted;

    BetOnCryptToken public token; 
    
    uint public start;
    
    uint public period;

    uint public hardcap;

    uint public rateboc;

    uint public softcap;

    uint public minboc;

    bool is_finishmining;

    State public state;

    uint public first;
    uint public second;
    uint public third; 
    uint public fourth; 
    uint public fifth;
    

    mapping(address => uint) public balances;
    uint public indexBalance;
    
    event Closed();
    event RefundsEnabled();
    event Refunded(address indexed beneficiary, uint256 weiAmount);  

    function CrowdsaleICO(address _tokencoin) {
        token = BetOnCryptToken(_tokencoin);
        is_finishmining = false;
        state = State.Active;
    } 

    function setParams(address _multisig, address _restricted, uint _period, uint _start, uint _rateboc, uint _minboc, uint _softcap, uint _hardcap, uint _restrictedPercent, uint _first, uint _second,  uint _third, uint _fourth, uint _fifth) onlyOwner {
      multisig = _multisig; 
      restricted = _restricted;    
      start = _start;      
      period = _period;      
      minboc = _minboc.mul(1000000000000000000);      
      rateboc = _rateboc.mul(1000000000000000000);      
      softcap = _softcap.mul(1000000000000000000);      
      hardcap = _hardcap.mul(1000000000000000000);
      if (_restrictedPercent > 0 && _restrictedPercent < 50){
        restrictedPercent = _restrictedPercent;      
      } 
      else{
        restrictedPercent = 40;
      }
      first  = _first;
      second = _second;
      third  = _third; 
      fourth = _fourth; 
      fifth  = _fifth;
    }

    modifier saleIsOn() {
    	require((now > start) && (now < (start + period * 1 days)));
    	_;
    }

    modifier isUnderHardcap() {
        require(multisig.balance <= hardcap);
        _;
    }

    modifier isUnderRefunds() {
        require((this.balance < softcap) && (now > (start + period * 1 days)));
        _;
    }

    function finishMinting() onlyOwner {
        require(this.balance >= softcap);
        multisig.transfer(this.balance);
        uint issuedTokenSupply = token.totalSupply() - token.lastTotalSupply();
        uint restrictedTokens = issuedTokenSupply.mul(restrictedPercent).div(100 - restrictedPercent);
        token.mint(restricted, restrictedTokens);
        token.finishMinting();
        is_finishmining = true;
    }



    function destroyCrowdsale() onlyOwner {
      require(state == State.Close);
      selfdestruct(owner);
    }

    function closeCrowdsale() onlyOwner {
      require(state == State.Active);
      require(now > (start + (period * 1 days)));
      require(this.balance >= softcap);
      state = State.Close;
      if (is_finishmining == false){
        finishMinting();
      }
      Closed();
    }

    function enableRefunds() onlyOwner isUnderRefunds public {
      require(state == State.Active);
      state = State.Refunding;
      RefundsEnabled();
    }

    function refund() isUnderRefunds public {
      require(state == State.Refunding);
      uint value = 0;
      value = balances[msg.sender]; 
      balances[msg.sender] = 0; 
      if (indexBalance > 0) {
         indexBalance --;
      }
      if (indexBalance == 0) {
        state = State.Close;
      }
      msg.sender.transfer(value); 
      Refunded(msg.sender, value);
    }


    function createTokens() isUnderHardcap saleIsOn payable {
        require(msg.sender != address(0));
        require(state == State.Active);
        uint tokens = rateboc.mul(msg.value).div(1 ether);
        require(tokens > minboc);
        uint bonusTokens = 0;
        if(now < (start + 6 days)) {
          bonusTokens = tokens.mul(first).div(100);
        } else if(now >= (start +  6 days) && now < (start + 12 days)) {
          bonusTokens = tokens.mul(second).div(100);
        } else if(now >= (start + 12 days) && now < (start + 18 days)) {
          bonusTokens = tokens.mul(third).div(100);
        } else if(now >= (start + 18 days) && now < (start + 24 days)) {
          bonusTokens = tokens.mul(fourth).div(100);
        } else if(now >= (start + 24 days)) {
          bonusTokens = tokens.mul(fifth).div(100);
        }
        tokens += bonusTokens;
        token.mint(this, tokens);
        token.transfer(msg.sender, tokens);
        balances[msg.sender] = balances[msg.sender].add(msg.value);
        indexBalance ++;
        
        
    }

    function sendTokens(address beneficiary, uint _tokens) onlyOwner public {
      uint value = _tokens.mul(1000000000000000000);
      token.mint(this, value);
      token.transfer(beneficiary, value);
    }

    function() external payable {
      createTokens();
    }
}

