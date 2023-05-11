var express = require('express');
var bodyParser = require('body-parser');
var appSettings = require('./Appsettings.json');
var Web3 = require('web3');
var contractABI = require('../TestDApp/test.json');
var nftContractABI = require('../TestDApp/auction.json');

var app = express();
var web3 = new Web3('http://localhost:8545');
var images = require('./Images.json');
// const endpoint = 'ws://localhost:8546';
// const web3 = new Web3(new Web3.providers.WebsocketProvider(endpoint));
var contractAddress = '0xFbC40C43dfEea100B0a3BC91eC24D241dB1D737d';

var contract = new web3.eth.Contract(contractABI, contractAddress);
// Use Images icon
app.use(express.static(__dirname + '/public'));

//using ejs
app.set('view engine', 'ejs');

app.use(bodyParser.urlencoded({ extended: true }));

//Api Calls
app.get('/NFTMarket', async function (req, res) {
    getNFTidCtr().then(data => {
        var promises = []
        for (var i = 0; i < data; i++) {
            promises.push(getNFTbyIndex(i))
        }
        Promise.all(promises).then((values) => {
            result ={}
            result["NFTs"] = converToNFTs(values)
            result["Images"] =images
            return result
        }).then((NFTResult)=>{
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
                        var address = req.query.address ? req.query.address : values[0]
                        return { 
                            "NFTs": NFTResult.NFTs,
                            "Images": NFTResult.Images,
                            "accounts": result,
                            "fixedDepositHistory": [],
                            "accountAddress": values,
                            "account": result[address],
                            "address": address ,
                            "errormsg": req.query.errormsg,
                            "redirected": req.query.redirected}
                    }).then((data) => {
                        fixeDepositHisPromise = []
                        if (data["accountAddress"].length > 0) {
                            for (var i = 0; i < data["accounts"][data["address"]].fixedDepositCounter; i++) {
                                fixeDepositHisPromise.push(getFixedDepositHistory(data["address"], i))
                            }
                            Promise.all(fixeDepositHisPromise).then((fixedDepositHistories) => {
                                data["fixedDepositHistory"] = convertToHistory(fixedDepositHistories)
                                return data
                            }).then((finalData) => {
                                console.log(finalData)
                                res.render('pages/userIndex', finalData)
                            })
                        }
                        else {
                            console.log(data)
                            res.render('pages/userIndex', data)
                        }
                    })
                })
            })
        })
    })
});

app.get('/', async function (req, res) {
    getNFTidCtr().then(data => {
        var promises = []
        for (var i = 0; i < data; i++) {
            promises.push(getNFTbyIndex(i))
        }
        Promise.all(promises).then((values) => {
            result ={}
            result["NFTs"] = converToNFTs(values)
            result["Images"] =images
            return result
        }).then((NFTResult)=>{
            getLoanReqestCtr().then((loanRequestCtr)=>{
                console.log("loanRequestCtr:: "+loanRequestCtr)
                var loanPromises = []
                for (var i = 0; i < loanRequestCtr; i++) {
                    loanPromises.push(getLoanReqestbyIndex(i))
                }
                Promise.all(loanPromises).then((loanResults) => {
                    console.log(loanResults)
                    NFTResult["loans"] = convertToLoanRequests(loanResults)
                    return NFTResult
                }).then((NFTLoanData)=>{
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
                                var address = req.query.address ? req.query.address : values[0]
                                return { 
                                    "NFTs": NFTLoanData.NFTs,
                                    "Images": NFTLoanData.Images,
                                    "loans": NFTLoanData.loans,
                                    "accounts": result,
                                    "fixedDepositHistory": [],
                                    "accountAddress": values,
                                    "account": result[address],
                                    "address": address ,
                                    "errormsg": req.query.errormsg,
                                    "redirected": req.query.redirected}
                            }).then((data) => {
                                fixeDepositHisPromise = []
                                if (data["accountAddress"].length > 0) {
                                    for (var i = 0; i < data["accounts"][data["address"]].fixedDepositCounter; i++) {
                                        fixeDepositHisPromise.push(getFixedDepositHistory(data["address"], i))
                                    }
                                    Promise.all(fixeDepositHisPromise).then((fixedDepositHistories) => {
                                        data["fixedDepositHistory"] = convertToHistory(fixedDepositHistories)
                                        return data
                                    }).then((finalData) => {
                                        res.render('pages/index', finalData)
                                    })
                                }
                                else {
                                    res.render('pages/index', data)
                                }
                            })
                        })
                    })
                })
            })
        })
    })
    
});


app.post('/SavingsDeposit', function(req, res, next){
    console.log(req.body)
    DepositAmount(req.body.address,0,req.body.amount).then(data =>{
        if(!data.errormsg){
            res.redirect('/?redirected=True&address='+req.body.address);
        }
        else{
            res.redirect('/?redirected=True&address='+req.body.address+'&errormsg='+data.errormsg);
        }
    })
 });


 app.post('/FixedDeposit', function(req, res, next){
    DepositAmount(req.body.address,1,req.body.amount).then(data =>{
        if(!data.errormsg){
            res.redirect('/?address='+req.body.address);
        }
        else{
            res.redirect('/?address='+req.body.address+'&errormsg='+data.errormsg);
        }
    })
 });

 app.post('/WithDrawFixedDeposit', function(req, res, next){
    console.log(req.body.address,1,req.body.amount,req.body.id)
    WithdrawAmount(req.body.address,1,req.body.amount,req.body.id).then(data =>{
        if(!data.errormsg){
            res.redirect('/?address='+req.body.address);
        }
        else{
            res.redirect('/?address='+req.body.address+'&errormsg='+data.errormsg);
        }
    })
 });

 app.post('/SubmitBid', function(req, res, next){
    console.log(req.query.address,req.body.nftId,req.body.amount)
    NFTBid(req.query.address,req.body.nftId,req.body.amount).then(data =>{
        if(!data.errormsg){
            res.redirect('/NFTMarket?address='+req.query.address);
        }
        else{
            res.redirect('/NFTMarket?address='+req.query.address+'&errormsg='+data.errormsg);
        }
    })
 });

 app.post('/RequestLoan', function(req, res, next){
    RequestLoan(req.body.address,req.body.amount,req.body.reason, req.body.collateralId).then(data =>{
        if(!data.errormsg){
            res.redirect('/?address='+req.body.address);
        }
        else{
            res.redirect('/?address='+req.body.address+'&errormsg='+data.errormsg);
        }
    })
 });

app.set('port', process.env.PORT || 8000);

var server = app.listen(app.get('port'), async function () {
    console.log('server up and running' + server.address().port);
    setInterval(triggerSmartContract, 600000);
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

function getNFTidCtr() {
    return new Promise(async (resolve, reject) => {
        resolve(contract.methods.NFTidCtr().call())
    })
}

function getNFTbyIndex(index) {
    return new Promise(async (resolve, reject) => {
        resolve(contract.methods.AuctionMap(index).call())
    })
}

function getLoanReqestbyIndex(index) {
    return new Promise(async (resolve, reject) => {
        resolve(contract.methods.ProposalsMap(index).call())
    })
}

function getLoanReqestCtr() {
    return new Promise(async (resolve, reject) => {
        resolve(contract.methods.ProposalCtr().call())
    })
}


async function DepositAmount(accountAddress,type,amount) {
    // console.log(web3.utils.toWei(amount, 'ether'))
    return new Promise(async (resolve, reject) => {
        try{
            var nounce = await web3.eth.getTransactionCount(accountAddress);
            var txHash = await web3.eth.sendTransaction({
                to: contract.options.address,
                data: contract.methods.Deposit(type).encodeABI(),
                from: accountAddress,
                gas: 10000000,
                gasPrice: 0,
                value: amount,
                nounce: nounce
            });
            var receipt = await web3.eth.getTransactionReceipt(txHash);
            console.log(receipt)
            resolve({status: "success"})
        }
        catch(error){
            console.log(error)
            resolve({status: "success"})
        }
    })
}

function NFTMint() {
    return new Promise(async (resolve, reject) => {
        try{
            var nounce = await web3.eth.getTransactionCount(accountAddress);
            var txHash = await web3.eth.sendTransaction({
                to: contract.options.address,
                data: contract.methods.NFTMint().encodeABI(),
                from: accountAddress,
                gas: 10000000,
                gasPrice: 0,
                value: 0,
                nounce: nounce
            });
            resolve({errormsg: {}, status: "success"})
        }
        catch(error){
            console.log(error)
            reject({errormsg: 'Error Minting NFT', status: "failure"})
        }
    })
}


function NFTBid(accountAddress, nftid, value) {
    return new Promise(async (resolve, reject) => {
        try{
            var nounce = await web3.eth.getTransactionCount(accountAddress);
            var txHash = await web3.eth.sendTransaction({
                to: contract.options.address,
                data: contract.methods.bid(nftid).encodeABI(),
                from: accountAddress,
                gas: 10000000,
                gasPrice: 0,
                value: value,
                nounce: nounce
            });
            resolve({errormsg: {}, status: "success"})
        }
        catch(error){
            console.log(error)
            reject({errormsg: 'Error Bidding NFT', status: "failure"})
        }
    })
}

function RequestLoan(accountAddress,amount,reason, collateralId) {
    return new Promise(async (resolve, reject) => {
        try{
            var nounce = await web3.eth.getTransactionCount(accountAddress);
            var txHash = await web3.eth.sendTransaction({
                to: contract.options.address,
                data: contract.methods.createProposal(accountAddress, amount, reason, collateralId).encodeABI(),
                from: accountAddress,
                gas: 10000000,
                gasPrice: 0,
                value: 0,
                nounce: nounce
            });
            resolve({errormsg: {}, status: "success"})
        }
        catch(error){
            console.log(error)
            reject({errormsg: 'Error Requesting loan', status: "failure"})
        }
    })
}

function WithdrawAmount(accountAddress, type, amount, fixedDepositIndex=0) {
    return new Promise(async (resolve, reject) => {
        try{
            var nounce = await web3.eth.getTransactionCount(accountAddress);
            var txHash = await web3.eth.sendTransaction({
                to: contract.options.address,
                data: contract.methods.WithDraw(amount, type, fixedDepositIndex).encodeABI(),
                from: accountAddress,
                gas: 10000000,
                gasPrice: 0,
                value: 0,
                nounce: nounce
            });
            // var receipt = await web3.eth.getTransactionReceipt(txHash);
            resolve({errormsg: {}, status: "success"})
        }
        catch(error){
            console.log(error)
            reject({errormsg: "Error Withdrawing money", status: "failure"})
        }
    })
}

function distributeSavingsInterest(){
    accountAddress = "0x44649853Fe6D3E1085B8A821DeECA343847B3bbD"
    return new Promise(async (resolve, reject) => {
        try{
            var nounce = await web3.eth.getTransactionCount(accountAddress);
            var txHash = await web3.eth.sendTransaction({
                to: contract.options.address,
                data: contract.methods.distributeSavingsInterest().encodeABI(),
                from: accountAddress,
                gas: 10000000,
                gasPrice: 0,
                value: 0,
                nounce: nounce
            });
            var receipt = await web3.eth.getTransactionReceipt(txHash);
            console.log(receipt)
            resolve({status: "success"})
        }
        catch(error){
            console.log(error)
            resolve({status: "success"})
        }
    })
}

function NFTCheckAuctionEnd(index){
    accountAddress = "0x44649853Fe6D3E1085B8A821DeECA343847B3bbD"
    return new Promise(async (resolve, reject) => {
        try{
            var nounce = await web3.eth.getTransactionCount(accountAddress);
            var txHash = await web3.eth.sendTransaction({
                to: contract.options.address,
                data: contract.methods.NFTCheckAuctionEnd(index).encodeABI(),
                from: accountAddress,
                gas: 10000000,
                gasPrice: 0,
                value: 0,
                nounce: nounce
            });
            var receipt = await web3.eth.getTransactionReceipt(txHash);
            console.log(receipt)
            resolve({status: "success"})
        }
        catch(error){
            console.log(error)
            resolve({status: "success"})
        }
    })
}

function converToNFTs(values){
    console.log(values)
    let result = []
    for (var value of values) {
        proposal = {}
        for (var idx in value) {
            switch (idx) {
                case "0":
                    proposal['beneficiary'] = value[idx]
                    break
                case "1":
                    proposal['auctionStart'] = value[idx]
                    break
                case "2":
                    proposal['auctionEnd'] = value[idx]
                    break
                case "3":
                    proposal['highestBidder'] = value[idx]
                    break
                case "4":
                    proposal['highestBid'] = value[parseInt(idx)]
                    break
                case "5":
                    proposal['ended'] = value[idx]
                    break
            }
        }
        result.push(proposal)
    }
    return result
}

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
                result['loanRequests'] = values[parseInt(idx)]
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
        }
        result.push(proposal)
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


function triggerSmartContract(){
        try{
            distributeSavingsInterest().then((data)=>{
                getNFTidCtr().then(data => {
                    console.log(data)
                    var promises = []
                    for (var i = 0; i < data; i++) {
                        promises.push(getNFTbyIndex(i))
                    }
                    Promise.all(promises).then((values) => {
                        return values
                    }).then((nftData)=>{
                        endNftPromise = []
                        count =0
                        for(var nft of nftData){
                            if(!nft['ended']){
                                endNftPromise.push(NFTCheckAuctionEnd(count))
                            }
                            count+=1;
                        }
                        Promise.all(endNftPromise).then((endNFSresponses) => {
                            console.log("endNFSresponses done")
                        }).then(()=>{
                            NFTMint().then((nftMintResponse) =>{
                                console.log("NFTMint done::"+nftMintResponse.status)
                            })
                        })
                    })
                })
            })
        }
        catch(err){
            console.log(err)
        }
}


