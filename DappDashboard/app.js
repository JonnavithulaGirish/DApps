var express = require('express');
var bodyParser = require('body-parser');
var appSettings = require('./Appsettings.json');
var Web3 = require('web3');
var contractABI = require('../TestDApp/test.json');

var app = express();
var web3 = new Web3('http://localhost:8545');
var contractAddress = '0xA3eD60E6Bb732D56619F80FF30a61D68861C77c4';
var contract = new web3.eth.Contract(contractABI, contractAddress);

// Use Images icon
app.use(express.static(__dirname + '/public'));

//using ejs
app.set('view engine', 'ejs');

app.use(bodyParser.urlencoded({ extended: true }));

//Api Calls
app.get('/', async function (req, res) {

    getAccountsAddressIndex().then(data => {
        var promises = []
        for (var i = 0; i < data; i++) {
            promises.push(getAccountbyIndex(i))
        }
        Promise.all(promises).then((values) => {
            accountPromise = []
            for (var value in values) {
                console.log(values[value])
                accountPromise.push(getAccounts(values[value]))
            }
            Promise.all(accountPromise).then((accounts) => {
                var result = {}
                var count = 0;
                for (var value in values) {
                    result[values[value]] = convertToAccount(accounts[count])
                    count += 1
                }
                return { "accounts": result, "fixedDepositHistory": [], "accountAddress": values }
            }).then((data) => {
                fixeDepositHisPromise = []
                if (data["accountAddress"].length > 0) {
                    for (var i = 0; i < data["accounts"][data["accountAddress"][0]].fixedDepositCounter; i++) {
                        fixeDepositHisPromise.push(getFixedDepositHistory(data['accountAddress'][0], i))
                    }
                    Promise.all(fixeDepositHisPromise).then((fixedDepositHistories) => {
                        for (var hist in fixedDepositHistories) {
                            data["fixedDepositHistory"].push(convertToHistory(hist))
                        }
                        return data
                    }).then((finalData) => {
                        //res.send(finalData)
                        console.log(finalData)
                        res.render('pages/index', finalData);
                    })
                }
                else {
                    //res.send(data)
                    res.render('pages/index', data);
                }
            })
        })
    })
});

app.set('port', process.env.PORT || 8000);

var server = app.listen(app.get('port'), async function () {
    console.log('server up and running' + server.address().port);
});

function getFixedDepositHistory(adress, index) {
    return new Promise(async (resolve, reject) => {
        resolve(contract.methods.fixedDepositsMap(adress, index).call())
    })
}

function getAccounts(address) {
    return new Promise(async (resolve, reject) => {
        resolve(contract.methods.Accounts(address).call())
    })
}

function getAccountbyIndex(index) {
    return new Promise((resolve, reject) => {
        resolve(contract.methods.AccountAddresses(index).call())
    })
}

function getAccountsAddressIndex() {
    return new Promise(async (resolve, reject) => {
        resolve(contract.methods.AccountAddressesIndex().call())
    })
}

async function DepositAmount(accountAddress,type,amount) {
    return new Promise(async (resolve, reject) => {
        try{
            var nounce = await web3.eth.getTransactionCount(accountAddress);
            var txHash = await web3.eth.sendTransaction({
                to: myContract.options.address,
                data: myContract.methods.Deposit(type).encodeABI(),
                from: accountAddress,
                gas: 10000000,
                gasPrice: 0,
                value: web3.utils.toWei(amount, 'ether'),
                nounce: nounce
            });
            var receipt = await web3.eth.getTransactionReceipt(txHash);
            resolve(receipt)
        }
        catch(error){
            console.log(error)
            reject(new Error('Error Depositing money'))
        }
    })
}

function WithdrawAmount(accountAddress, type, amount, fixedDepositIndex=0) {
    return new Promise(async (resolve, reject) => {
        try{
            var nounce = await web3.eth.getTransactionCount(accountAddress);
            var txHash = await web3.eth.sendTransaction({
                to: myContract.options.address,
                data: myContract.methods.WithDraw(amount, type, fixedDepositIndex).encodeABI(),
                from: accountAddress,
                gas: 10000000,
                gasPrice: 0,
                value: 0,
                nounce: nounce
            });
            var receipt = await web3.eth.getTransactionReceipt(txHash);
            resolve(receipt)
        }
        catch(error){
            console.log(error)
            reject(new Error('Error Depositing money'))
        }
    })
}


// function CreateAccount(initialDeposit) {
//     return new Promise(async (resolve, reject) => {
        
//     })
// }


function convertToAccount(values) {
    let result = {}
    for (var idx in values) {
        switch (idx) {
            case "0":
                result['savingBalance'] = values[parseInt(idx)]
                break
            case "1":
                result['fixedBalance'] = values[parseInt(idx)]
                break
            case "2":
                result['loanRequests'] = convertToLoanRequests(values[parseInt(idx)])
                break
            case "3":
                result['isNotEmpty'] = values[parseInt(idx)]
                break
            case "4":
                result['savingBalanceHistory'] = convertToHistory(values[parseInt(idx)])
                break
            case "5":
                result['fixedDepositCounter'] = values[parseInt(idx)]
                break
        }
    }
    return result
}

function convertToLoanRequests(values) {
    console.log(values)
    let result = []
    for (var value of values) {
        proposal = {}
        for (var idx in value) {
            switch (idx) {
                case "0":
                    proposal['recipient'] = value[parseInt(idx)]
                    break
                case "1":
                    proposal['amount'] = value[parseInt(idx)]
                    break
                case "2":
                    proposal['approved'] = value[parseInt(idx)]
                    break
                case "3":
                    proposal['approversTotalStake'] = value[parseInt(idx)]
                    break
                case "4":
                    proposal['requestMsg'] = value[parseInt(idx)]
                    break
                case "5":
                    proposal['isNotEmpty'] = value[parseInt(idx)]
                    break
            }
            result.push(proposal)
        }
    }
    return result
}


function convertToHistory(values) {
    let result = []
    for (var value of values) {
        history = {}
        for (var idx in value) {
            switch (idx) {
                case "0":
                    history['amount'] = value[parseInt(idx)]
                    break
                case "1":
                    history['time'] = value[parseInt(idx)]
                    break
                case "2":
                    history['isDeposit'] = value[parseInt(idx)]
                    break
            }
        }
        result.push(history)
    }
    return result
}