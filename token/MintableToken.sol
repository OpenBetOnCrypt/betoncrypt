/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com
 * Based on code by TokenMarketNet: https://github.com
 */

contract MintableToken is StandardToken, Ownable {
    
  event Mint(address indexed to, uint256 amount);
  
  event MintFinished();

  bool public mintingFinished = false;
  uint256 public lastTotalSupply = 0;

  address public saleAgent = 0;



  modifier canMint() {
    require(!mintingFinished);
    _;
  }


  function setSaleAgent(address newSaleAgent) public {
    require(msg.sender == saleAgent || msg.sender == owner);
    saleAgent = newSaleAgent;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will recieve the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) canMint returns (bool) {
    require(msg.sender == saleAgent); 
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */

  function finishMinting() returns (bool) {
    require((msg.sender == saleAgent) || (msg.sender == owner)); 
    lastTotalSupply = totalSupply;
    mintingFinished = true;
    MintFinished();
    return mintingFinished;
  }
  function startMinting()  returns (bool) {
    require((msg.sender == saleAgent) || (msg.sender == owner)); 
    mintingFinished = false;
    return mintingFinished;
  }
  
}

