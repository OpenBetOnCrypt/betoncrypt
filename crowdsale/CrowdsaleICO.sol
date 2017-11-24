contract CrowdsaleICO is Ownable {
    
    using SafeMath for uint;
    
    enum State { Active, Refunding, Close }
    
    address public multisig;

    uint public restrictedPercent;

    address public restricted;

    BetOnCryptToken public token; 
    
    uint public start;
    
    uint public period;

    uint public hardcapethers;

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

 

    function changeMultisig(address _msig) onlyOwner {
      multisig = _msig; 
      restricted = multisig;    
    }

    function changeRestricted(address _restricted) onlyOwner {
      restricted = _restricted;      
    }

    function changeStart(uint _start) onlyOwner {
      start = _start;      
    }

    function changeMinboc(uint _minboc) onlyOwner {
      minboc = _minboc;      
    }

    function changePeriod(uint _period) onlyOwner {
      period = _period;      
    }

    function changeRateboc(uint _rateboc) onlyOwner {
      rateboc = _rateboc.mul(1000000000000000000);      
    }

    function changeHardcapethers(uint _hardcapethers) onlyOwner {
      hardcapethers = _hardcapethers.mul(1000000000000000000);    
      softcap = hardcapethers; 
    }

    function changeSoftcap(uint _softcap) onlyOwner {
      softcap = _softcap.mul(1000000000000000000);      
    }

    function changeBonus(uint _first, uint _second,  uint _third, uint _fourth, uint _fifth) onlyOwner {
      first  = _first;
      second = _second;
      third  = _third; 
      fourth = _fourth; 
      fifth  = _fifth;
    }

    function changeRestrictedPercent(uint _restrictedPercent) onlyOwner {
      if (_restrictedPercent > 0 && _restrictedPercent < 50){
        restrictedPercent = _restrictedPercent;      
      } 
      else{
        restrictedPercent = 40;
      }
    } 

    modifier saleIsOn() {
    	require((now > start) && (now < (start + period * 1 days)));
    	_;
    }

    modifier isUnderHardcapethers() {
        require(multisig.balance <= hardcapethers);
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


    function createTokens() isUnderHardcapethers saleIsOn payable {
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

