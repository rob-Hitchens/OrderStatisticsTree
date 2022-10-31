import pytest
#from brownie import chain

############ Mocks ########################
@pytest.fixture(scope="module")
def treeMock(accounts, MockHOSTV1, HitchensOrderStatisticsTreeLibV1):
    #lib = accounts[0].deploy(HitchensOrderStatisticsTreeLibV1)
    mock = accounts[0].deploy(MockHOSTV1)
    yield mock

