var web3 = new Web3(Web3.givenProvider);
var contractInstance;
var contractAddress = "0xF10fbfb65f8BC5e47340f9a29BCE13EAc418c04f";

$(document).ready(function() {
    window.ethereum.enable().then(function(accounts){
      contractInstance = new web3.eth.Contract(abi, contractAddress, {from: accounts[0]});
      contractInstance.methods.getPot().call().then(function(res){
        $("#pot").text(res/1e18);
      });
      contractInstance.methods.getBalance().call().then(function(res){
        $("#balance").text(res/1e18);
      });
    });

    $("#place-bet").click(callPlaceBet);
    $("#flip-coin").click(callFlipCoin);
    $("#pay-out").click(callPayOut);

    $("#add-pot").click(callAddPot);
    $("#rm-pot").click(callRemovePot);
    $("#btn-unlock").click(callUnlock);
});

function callPlaceBet() {
    var betAmount = $("input[name=bet]:checked").val();

    contractInstance.methods.placeBet().send({value: web3.utils.toWei(betAmount, "ether"), gas: 1000000}).then(function(){
      $("#message").text("Bet placed successfully!");
    });
}

function callFlipCoin(){

    web3.eth.getGasPrice().then(function(res){
      contractInstance.methods.startFlipCoin().send({value: res, gas: 1000000}).then(function(){
        $("#message").text("Flipping coin! Please wait for result...");
      });
    });
}

  function callPayOut(){

    contractInstance.methods.getBalance().call().then(function(res){
      contractInstance.methods.payOut(res).send({gas: 1000000}).then(function(){
        $("#message").text("Winnings have been withdrawn");
      });
    });
  }

  function callAddPot(){
    var _balance = $("#pot-increase").val();

    contractInstance.methods.addPot().send({value: web3.utils.toWei(_balance.toString(),"ether"), gas: 1000000}).then(function(){
      alert("Done");
    });
  }

  function callRemovePot(){
    var _balance = $("#pot-decrease").val();

    contractInstance.methods.removePot(web3.utils.toWei(_balance.toString(),"ether")).send({gas: 1000000}).then(function(){
          alert("Done");
    });
  }

  function callUnlock(){
    var _address = $("#locked-address").val();

    contractInstance.methods.unlockPlayer(_address).send({gas: 1000000}).then(function(){
      alert("Done");
    });
  }

/*
  contractInstance.methods.addPerson(age, height, name, gender).send({value: web3.utils.toWei("1", "ether"), gas: 1000000})
    .on('transactionHash', function(hash){
      console.log("tx hash");
    })
    .on('confirmation', function(confirmationNumber, receipt){
        console.log("conf");
    })
    .on('receipt', function(receipt){
      console.log(receipt);
    })
  }

*/
