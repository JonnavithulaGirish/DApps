var Web3 = require('web3');
const endpoint = 'ws://localhost:8546';
const web3 = new Web3(new Web3.providers.WebsocketProvider(endpoint));
var contractABI = require('../TestDApp/test.json');
var contractAddress = '0xA0EDf95cf27c621f054609523AB8eFd0904730Cb';
var contract = new web3.eth.Contract(contractABI, contractAddress);

// console.log(JSON.stringify(contract))
// watch for changes in the callback
// var event = contract.events.Transfer(function(error, result) {
//     if (!error) {
//         // var args = result.returnValues;
//         console.log(JSON.stringify(result));
//     }
//     console.log(error)
// });

// var event = contract.events.myString(function(error, result) {
//     if (!error) {
//         console.log(JSON.stringify(result));
//     }
//     console.log(error)
// });

contract.events.myString()
  .on('data', event => {
    console.log(event.returnValues);
  })
  .on('error', console.error);

  contract.events.Transfer()
  .on('data', event => {
    console.log(event.returnValues);
  })
  .on('error', console.error);
  