import pytest
import logging
from brownie import chain, Wei, reverts
LOGGER = logging.getLogger(__name__)
from web3 import Web3
from random import randrange

PRICES_0 = [randrange(1e6, 3e6) for x in range(21)]
KEYS_0 = [
    0x0000000000000000000000000000000000000000000000000000000000000001,
    0x0000000000000000000000000000000000000000000000000000000000000002
]


def test_insert_random_feed(accounts, treeMock):
    for x in PRICES_0:
        treeMock.insertKeyValue(KEYS_0[0], x, {"from": accounts[0]})
        logging.info('NodeCount {:3d}, root: {:7d}, median ={:7d}, after insert {:7d}'.format(
            treeMock.valueKeyCount(),
            treeMock.treeRootNode(),
            treeMock.medianValue(),
            x
        ))
    #insert second key to one of node
    treeMock.insertKeyValue(KEYS_0[1], PRICES_0[1], {"from": accounts[0]})

    # Lets sort original array
    PRICES_0.sort()
    median_rank = len(PRICES_0)//2 + len(PRICES_0)%2
    
    logging.info('Original sorted array with len={} has median:{}'.format(
        len(PRICES_0),
        PRICES_0[median_rank - 1]
    ))
    assert treeMock.valueKeyCount() == len(PRICES_0) +1
    
        
def test_remove_from_top(accounts, treeMock):
    with reverts("OrderStatisticsTree(407) - Value to delete cannot be zero"):
        treeMock.removeKeyValue(KEYS_0[0], 0, {"from": accounts[0]}) 
    with reverts("OrderStatisticsTree(408) - Value to delete does not exist."):
        treeMock.removeKeyValue(KEYS_0[0], PRICES_0[0]+1, {"from": accounts[0]})     
    
    tx = treeMock.removeKeyValue(KEYS_0[0], PRICES_0[0], {"from": accounts[0]}) 
    assert treeMock.valueExists(PRICES_0[0]) == False 
    
    logging.info('NodeCount {:3d}, root: {:7d}, median ={:7d}, after remove {:7d}'.format(
            treeMock.valueKeyCount(),
            treeMock.treeRootNode(),
            treeMock.medianValue(),
            PRICES_0[0]
        ))
    PRICES_0.remove(PRICES_0[0])
    
    PRICES_0.sort()
    median_rank = len(PRICES_0)//2 + len(PRICES_0)%2
    assert treeMock.valueKeyCount() == len(PRICES_0) +1

def test_remove_from_end(accounts, treeMock):
    tx = treeMock.removeKeyValue(KEYS_0[0], PRICES_0[-1], {"from": accounts[0]}) 
    assert treeMock.valueExists(PRICES_0[-1]) == False 
    
    logging.info('NodeCount {:3d}, root: {:7d}, median ={:7d}, after remove {:7d}'.format(
            treeMock.valueKeyCount(),
            treeMock.treeRootNode(),
            treeMock.medianValue(),
            PRICES_0[-1]
        ))
    PRICES_0.remove(PRICES_0[-1])
    PRICES_0.sort()
    #median_rank = len(PRICES_0)//2 + len(PRICES_0)%2
    assert treeMock.valueKeyCount() == len(PRICES_0) +1    

def test_remove_from_center(accounts, treeMock):
    median_rank = len(PRICES_0)//2 + len(PRICES_0)%2
    tx = treeMock.removeKeyValue(KEYS_0[0], PRICES_0[median_rank], {"from": accounts[0]}) 
    assert treeMock.valueExists(PRICES_0[median_rank]) == False 
    
    logging.info('NodeCount {:3d}, root: {:7d}, median ={:7d}, after remove {:7d}'.format(
            treeMock.valueKeyCount(),
            treeMock.treeRootNode(),
            treeMock.medianValue(),
            PRICES_0[median_rank]
        ))
    PRICES_0.remove(PRICES_0[median_rank])
    PRICES_0.sort()
    assert treeMock.valueKeyCount() == len(PRICES_0)+1         

def test_remove_from_center(accounts, treeMock):
    for x in PRICES_0:
        tx = treeMock.removeKeyValue(KEYS_0[0], x, {"from": accounts[0]})
        if treeMock.valueExists(x): 
            treeMock.removeKeyValue(KEYS_0[1], x, {"from": accounts[0]})

