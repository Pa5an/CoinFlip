// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title CoinFlip 
   @author Kancharapu Pavan (kancharapu.1@iitj.ac.in)
 * @dev A “Coin Flip” betting game in the Solidity language using the Harmony testnet and Harmony VRF (Verifiable Random Function).
 */
contract CoinFlip{

    // Set contract deployer as owner
    // Private because you never know (https://www.gamblingbitcoin.com/bitcoin-gambling-legal/#:~:text=visa%20to%20Macau.-,India,-Online%20gambling%20is)
    address private owner;
    
    // modifier to check if caller is owner
    modifier isOwner {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    constructor(){
        owner = msg.sender;
    }


    //event for when a user places a bet.
    event betPlaced(uint8 bet, address userAdd, uint amount);

    //event for bet that a user wins.
    event betWon(uint8 bet, address userAdd, uint amount);


    struct User{
        // Total amount of money the user has (1000 by default)
        uint userBalance;
        // Amount of money the user has bet on the current flip
        uint betAmount;
        // 0: Heads, 1: Tails
        uint8 expectedOutcome;
        // 0: new user and not betted 1: old user and no currnet bets, 2: betted and result pending
        uint8 status;
    }


    uint public userCount=0; // total users


    // Mapping to store structure of every user
    mapping(address => User) public users;

    address[] usersBetted; // stores all users who have placed a bet
    
 /**
     * A user can place its bet (New user get 1000 bucks)
     * @param  _bet   0: Heads, 1: Tails
     * @param _amount the amount user wants to bet
    */
    function placeBet(uint8 _bet, uint _amount) public {
        
        if(users[msg.sender].status==0){//checks if it is a new user
            users[msg.sender].userBalance = 1000;
            users[msg.sender].status=1;
        }
        require(users[msg.sender].userBalance >= _amount, "Bet amount should be greater than 0 and less than user balance");
        require(users[msg.sender].status==1, "User has already betted");

        users[msg.sender].betAmount = _amount;
        users[msg.sender].userBalance = users[msg.sender].userBalance - _amount;
        users[msg.sender].expectedOutcome = _bet;
        users[msg.sender].status=2;
        usersBetted.push(msg.sender);

        emit betPlaced(_bet, msg.sender, _amount);
    }

    // Concludes all the current bets (invoked only by the owner)
    // Removing isOwner modifier to allow this function to be invoked by peps from `jobs@dyeus.co`
    function rewardBets() public {

        uint8 outcome =uint8(uint(vrf())%2);// random number generated using harmony vrf

        for(uint i=0;i<=usersBetted.length;i++){
           address userAdd = usersBetted[i];
           if(users[userAdd].expectedOutcome == outcome){
                users[userAdd].userBalance = users[userAdd].userBalance + 2*users[userAdd].betAmount;
                users[userAdd].betAmount = 0;
                emit betWon(outcome, userAdd, 2*users[userAdd].betAmount);
           }
            users[userAdd].status=1;
        }

        delete usersBetted;
    }

    // Harmony vrf implementation
    function vrf() public view returns (bytes32 result) {
        uint[1] memory bn;
        bn[0] = block.number;
        assembly {
            let memPtr := mload(0x40)
            if iszero(staticcall(not(0), 0xff, bn, 0x20, memPtr, 0x20)) {
                invalid()
            }
            result := mload(memPtr)
        }
  }

}
