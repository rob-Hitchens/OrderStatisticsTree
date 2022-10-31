import pytest
import logging
from brownie import chain, Wei, reverts
LOGGER = logging.getLogger(__name__)
from web3 import Web3

PRICES_0 = [10000,11111,22222, 33333, 44444]
PRICES_1 = [10, 100, 110, 200, 300]
KEYS_0 = [
    0x0000000000000000000000000000000000000000000000000000000000000001,
    0x0000000000000000000000000000000000000000000000000000000000000002,
    0x0000000000000000000000000000000000000000000000000000000000000003,
    0x0000000000000000000000000000000000000000000000000000000000000004,
    0x0000000000000000000000000000000000000000000000000000000000000005
]


def test_insert(accounts, treeMock):
    with reverts("OrderStatisticsTree(401) - Starting value cannot be zero"):
        treeMock.nextValue(0)
    with reverts("OrderStatisticsTree(405) - Value to insert cannot be zero"):
        treeMock.insertKeyValue(KEYS_0[0],0, {"from": accounts[0]})    
    with reverts("OrderStatisticsTree(404) - Value does not exist."):
        treeMock.getValueKey(77777,0)    
    assert treeMock.valueRank(  KEYS_0[0]) == 0
    assert treeMock.valuesBelow(KEYS_0[0]) == 0    
    treeMock.insertKeyValue(KEYS_0[0], PRICES_0[0], {"from": accounts[0]})
    with reverts("OrderStatisticsTree(406) - Value and Key pair exists. Cannot be inserted again."):
        treeMock.insertKeyValue(KEYS_0[0], PRICES_0[0], {"from": accounts[0]})
    assert treeMock.valueKeyCount() == 1
    assert treeMock.medianValue() == PRICES_0[0]
    logging.info('Median after 1 insert:{}'.format(treeMock.medianValue()))
    logging.info(
        'Node({}):parent = {}, left = {}, right = {}, isRed = {}, keyCount = {}, count = {}'.format(
            PRICES_0[0],
            treeMock.getNode2(PRICES_0[0])[0],
            treeMock.getNode2(PRICES_0[0])[1],
            treeMock.getNode2(PRICES_0[0])[2],
            treeMock.getNode2(PRICES_0[0])[3],
            treeMock.getNode2(PRICES_0[0])[4],
            treeMock.getNode2(PRICES_0[0])[5],
    ))

def test_feed_one_key_seven_prices(accounts, treeMock):
    [treeMock.insertKeyValue(KEYS_0[0], x, {"from": accounts[0]}) for x in PRICES_1]
    assert treeMock.valueKeyCount() == 6
    assert treeMock.medianValue() == PRICES_1[2]
    logging.info('Median after PRICES_1 insert:{}'.format(treeMock.medianValue()))
    for i in PRICES_1:
        logging.info(
        'Node({:5d}):parent = {:6d}, left = {:6d}, right = {:6d}, isRed = {:<}, keyCount = {:3d}, count = {:3d}'.format(
            i,
            treeMock.getNode2(i)[0],
            treeMock.getNode2(i)[1],
            treeMock.getNode2(i)[2],
            treeMock.getNode2(i)[3],
            treeMock.getNode2(i)[4],
            treeMock.getNode2(i)[5],
    ))
    with reverts("OrderStatisticsTree(403) - Value does not exist."):
        treeMock.getNode2(777777777)

def test_feed_five_keys_one_price(accounts, treeMock):
    [treeMock.insertKeyValue(x, PRICES_0[4], {"from": accounts[0]}) for x in KEYS_0]
    feed_count = treeMock.valueKeyCount()
    assert  feed_count == 11
     
    logging.info('Median after same price insert:{}'.format(treeMock.medianValue()))
    list_from_tree = []
    #list_from_tree.append(treeMock.firstValue())
    #logging.info('First value:{}'.format(list_from_tree[0]))
    for x in range(feed_count):
        val_at_rank = treeMock.valueAtRank(x+1)
        list_from_tree.append(val_at_rank)
        logging.info('Tree:value at rank( {:2g}):    {:5d}, keys count {}, Above {}, Below {}'.format(
            #list_from_tree[x],
            #treeMock.valueRank(list_from_tree[x]),
            x+1,
            val_at_rank,
            treeMock.getNodeKeysCount(val_at_rank),
            treeMock.valuesBelow(val_at_rank),
            treeMock.valuesAbove(val_at_rank)
        ))
        assert  treeMock.getNode2(val_at_rank)[5] + treeMock.getNode2(val_at_rank)[4] ==  treeMock.getNode(treeMock.valueAtRank(x+1))[5]
        if  treeMock.getNodeKeysCount(val_at_rank) == 1:
            assert  treeMock.valueRank(val_at_rank) == x + 1 
    logging.info('Price list from tree:{}'.format(list_from_tree))
    assert  treeMock.medianValue() == list_from_tree[5]
    assert  treeMock.valueExists(777777777777) == False
    assert treeMock.firstValue() == list_from_tree[0]
    assert treeMock.lastValue() == list_from_tree[-1] 
    for x in range(len(list_from_tree)):
        logging.info('list_from_tree[{}] = {}'.format(x,list_from_tree[x]))
        logging.info(
        'Node({:5d}):parent = {:6d}, left = {:6d}, right = {:6d}, isRed = {:<}, keyCount = {:3d}, count = {:3d}'.format(
            x,
            treeMock.getNode2(list_from_tree[x])[0],
            treeMock.getNode2(list_from_tree[x])[1],
            treeMock.getNode2(list_from_tree[x])[2],
            treeMock.getNode2(list_from_tree[x])[3],
            treeMock.getNode2(list_from_tree[x])[4],
            treeMock.getNode2(list_from_tree[x])[5],
        ))
        logging.info(treeMock.getValueKey(list_from_tree[x],0))

        if  x > 0:
            if  treeMock.getNodeKeysCount(list_from_tree[x]) == 1:
                assert treeMock.prevValue(list_from_tree[x]) == list_from_tree[x - 1] 
                assert treeMock.valueRank(list_from_tree[x]) == x + 1
                assert treeMock.valuesBelow(list_from_tree[x]) == x
                assert treeMock.nextValue(list_from_tree[x]) == list_from_tree[x + 1]        

