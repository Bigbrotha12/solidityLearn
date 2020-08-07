// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.5.12;
import "./Ownable.sol";
import "./provableAPI.sol";

contract coinFlip is Ownable, usingProvable {

    uint256 constant RANDOM_BYTES = 1;                  //Number of bytes being requested from Oracle.
    uint private pot;                                   //Global variable tracking contract balance.
    uint private committedPot;                          //Variable to track balance of pot claimable by players.
    mapping(bytes32 => address) private playerQuery;    //Mapping to tie Oracle query to each player.
    mapping(address => uint) private playerOutcome;     //Mapping to track win/loss outcome for each player.
    mapping(address => uint) private playerBalance;     //Mapping to track balance placed as bet by each player.
    mapping(address => bool) private awaitingQuery;     //Tracks players awaiting response from Oracle.
    event LogNewQuery(string);                          //Event generated after each Oracle query is submitted.
    event generatedRandomNumber(uint256);               //Event generated after Oracle callback with new random number.

    /** @notice Allow player to add ETH balance to his/her account.
      *  Minimun amount to add = 0.1 Ether.
      *  Player may not increase bet while waiting for Oracle response.
      *  Balance to be added to be determined by transaction value.
      *  Updated balance will be shown to user in browser.
     **/
    function placeBet() public payable {
      require(msg.value >= 0.1 ether);
      require(!awaitingQuery[msg.sender]);
      playerBalance[msg.sender] += msg.value;
      pot += msg.value;
      committedPot += msg.value;
    }

    /** @notice Issues query to Oracle for a random number.
      * User must pay the gas fee and bet atleast 0.1 ether.
      * User cannot make another Oracle request while awaiting another query.
      * player balance to bet must not exceed half the size of the available pot.
     **/
    function startFlipCoin() public payable {
      require(playerBalance[msg.sender] <= ((pot - committedPot) / 2),"Not enough balance in pot to cover your bet");
      require(playerBalance[msg.sender] >= 0.1 ether, "You need at least 0.1 ether to play");
      require(!awaitingQuery[msg.sender],"You are still waiting for results");

      //bytes32 queryId = devQuery();                     ////For testing only!

      uint256 QUERY_EXECUTION_DELAY = 0;                //Delay before Oracle executes query. Should be no delay.
      uint256 GAS_FOR_CALLBACK = 200000;                //Gas needed for Oracle callback transaction. Paid by user.
      bytes32 queryId = provable_newRandomDSQuery(      //Query ID to be used to track outcome for each player.
        QUERY_EXECUTION_DELAY,
        RANDOM_BYTES,
        GAS_FOR_CALLBACK);


      playerQuery[queryId] = msg.sender;
      awaitingQuery[msg.sender] = true;
      committedPot += playerBalance[msg.sender];        //Reserve pot balance in case player wins.
      emit LogNewQuery("Provable request sent. Waiting for response...");

      //__callback(queryId, "1", bytes("test"));          //For testing only!

    }

    /*
    function devQuery() private returns (bytes32){      //For testing only!
      return bytes32(keccak256("test"));
    }
    */

    /** @notice Private function to be called once Oracle calls back contract with response.
      * Function will then determine the win/lose case for the given player.
      * @param player is the address of player who initiated Oracle call.
     **/
    function resolveFlip(address player) private {
      uint outcome = playerOutcome[player];
      if(outcome == 1){
        playerBalance[player] *= 2;
      }
      else{
        committedPot -= (playerBalance[player]*2);
        playerBalance[player] = 0;
      }
      awaitingQuery[player] = false;
    }

    /** @notice Allows player to withdraw their winnings from the contracts pot.
      *  Amount to be withdrawn must be less than or equal to the player's balance.
      *  Players may not withdraw bet while awaiting for Oracle query.
      * @param amount is ether value to be paid to player.
     **/
    function payOut(uint amount) public {
      require(amount <= playerBalance[msg.sender]);
      require(!awaitingQuery[msg.sender]);

      playerBalance[msg.sender] -= amount;
      pot -= amount;
      committedPot -= amount;
      msg.sender.transfer(amount);
    }

    /** @notice Getter function for player's current ether balance.
      * @return returns the current balance bet by the player.
     **/

    function getBalance() public view returns(uint){
      return playerBalance[msg.sender];
    }

    /** @notice Getter function to obtain current balance of contract.
     **/
    function getPot() public view returns (uint){
      return pot;
    }

    /** @notice Getter function to obtain current balance of contract claimable by players.
     **/
    function getCommitedPot() public view returns (uint){
      return committedPot;
    }

    /** @notice Admin function to add claimable ether balance to the contract.
     **/
    function addPot() public payable onlyOwner {
      pot += msg.value;
    }

    /** @notice Admin function to remove specified available ether balance
     *  from the contract.
     *  Admin is not allowed to withdraw balance claimable by players.
     *  @param amount is balance to be withdrawn from contract.
     **/
    function removePot(uint amount) public onlyOwner {
      require(amount <= (pot - committedPot));
      pot -= amount;
      msg.sender.transfer(amount);
    }

    /** @notice Admin function to unlock player funds in case of Oracle failure.
      * To be used in case of emergency funds recovery.
     **/
     function unlockPlayer(address player) public onlyOwner {
       awaitingQuery[player] = false;
     }

    /** @notice Oracle call function returning a random string.
      * Function hashes the string to produce pseudo-random number either 0 or 1.
      * @param _queryId is used to determine player who called this query.
      * @param _result is random string generated by Oracle.
      * @param _proof is unused.
     **/
    function __callback(bytes32 _queryId, string memory _result, bytes memory _proof) public {
      require(msg.sender == provable_cbAddress());
      address player = playerQuery[_queryId];                                       //Variable to hold address of player who called this query.
      require(awaitingQuery[player]);
      uint256 randomNumber = uint256(keccak256(abi.encodePacked(_result))) % 2;     //Hashing of string _result to produce pseudo-random number.
      playerOutcome[player] = randomNumber;
      emit generatedRandomNumber(randomNumber);
      resolveFlip(player);
    }

}
