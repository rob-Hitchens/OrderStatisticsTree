import pytest
import logging
from brownie import chain, Wei, reverts
LOGGER = logging.getLogger(__name__)
from web3 import Web3

PRICES_0 = [10000,10000,10000]
KEYS_0 = [
    0x0000000000000000000000000000000000000000000000000000000000000001,
    0x0000000000000000000000000000000000000000000000000000000000000002,
    0x0000000000000000000000000000000000000000000000000000000000000003,
]


def test_feed_one_price(accounts, treeMock):
    [treeMock.insertKeyValue(x, PRICES_0[0], {"from": accounts[0]}) for x in KEYS_0]
    feed_count = treeMock.valueKeyCount()
    assert  feed_count == 3
    #logging.info('Median after same price insert:{}'.format(treeMock.medianValue()))
    list_from_tree = []
    list_from_tree.append(treeMock.firstValue())
    logging.info('Rank of {} is {}'.format(PRICES_0[0], treeMock.valueRank(PRICES_0[0])))
    logging.info('median Rank after insert 3 same values:{}'.format(treeMock.mock1(50)))
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
    for x in range (1,100):
        logging.info('median Rank from {} values:{}'.format(x,treeMock.mock2(50,x)))
    
    logging.info('Price list from tree:{}'.format(list_from_tree))

