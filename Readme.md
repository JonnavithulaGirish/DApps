# DApp


### Update Code in test.vy
    1)  Create bytecode using :: vyper -f bytecode test.vy > bytecode.bytecode  -- useful for deployment
    2)  Create ABI vyper -f abi test.vy > test.json -- Useful in client side code/Fronted 
    
## Deployments can be done using deploySc python script
    1)  post successful deployment returns the contract_id -- useful in client side code/Fronted 

## Example usage of ABI is used in testAbi.py
    1) Use Abi json file and contract id generated to communicate with smart contract
    2) getBalance and CreateAccounts use 2 different approaches to call smartContract methods. Former method is used when smartContract function doesnt update state, later method is used if state is updated.


