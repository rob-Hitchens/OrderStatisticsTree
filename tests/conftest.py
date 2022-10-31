import pytest

from brownie._config import CONFIG


pytest_plugins = [
   #"fixtures.conftest",
   "fixtures.accounts",
   "fixtures.deploy_env"
  ]

@pytest.fixture(scope="session")
def is_forked():
    yield "fork" in CONFIG.active_network['id']
