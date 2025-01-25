// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MockVRFCoordinatorV2 {
    uint96 private constant SUBSCRIPTION_BALANCE = 1000000000000000000;
    
    struct Subscription {
        uint96 balance;
        bool active;
    }
    
    mapping(uint64 => Subscription) private _subscriptions;
    mapping(uint256 => address) private _consumers;
    uint256 private _nextRequestId = 1;
    
    event RandomWordsRequested(
        bytes32 indexed keyHash,
        uint256 requestId,
        uint256 preSeed,
        uint64 indexed subId,
        uint16 minimumRequestConfirmations,
        uint32 callbackGasLimit,
        uint32 numWords,
        address indexed sender
    );
    
    event RandomWordsFulfilled(
        uint256 indexed requestId,
        uint256 outputSeed,
        uint96 payment,
        bool success
    );

    constructor() {
        // Create a default subscription with ID 1
        _subscriptions[1] = Subscription({
            balance: SUBSCRIPTION_BALANCE,
            active: true
        });
    }

    function requestRandomWords(
        bytes32 keyHash,
        uint64 subId,
        uint16 requestConfirmations,
        uint32 callbackGasLimit,
        uint32 numWords
    ) external returns (uint256) {
        require(_subscriptions[subId].active, "subscription not active");
        
        uint256 requestId = _nextRequestId++;
        _consumers[requestId] = msg.sender;
        
        emit RandomWordsRequested(
            keyHash,
            requestId,
            0,
            subId,
            requestConfirmations,
            callbackGasLimit,
            numWords,
            msg.sender
        );
        
        // Automatically fulfill the request
        fulfillRandomWords(requestId, numWords);
        
        return requestId;
    }

    function fulfillRandomWords(uint256 requestId, uint32 numWords) public {
        address consumer = _consumers[requestId];
        require(consumer != address(0), "request not found");
        
        uint256[] memory randomWords = new uint256[](numWords);
        for(uint32 i = 0; i < numWords; i++) {
            randomWords[i] = uint256(keccak256(abi.encode(requestId, i)));
        }
        
        VRFConsumerBaseV2(consumer).rawFulfillRandomWords(requestId, randomWords);
        
        emit RandomWordsFulfilled(requestId, 0, 0, true);
        delete _consumers[requestId];
    }
}

interface VRFConsumerBaseV2 {
    function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external;
}