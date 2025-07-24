.PHONY: test compile coverage deploy verify

include .env

build:
	forge build

test:
	forge test -vv

coverage:
	forge coverage

format:
	forge fmt

deploy-verify:
	forge script script/BlockTenderID.s.sol:BlockTenderIDScript --rpc-url ${RPC_URL} --private-key ${PRIVATE_KEY} --broadcast --verify --verifier ${VERIFIER} --verifier-url ${VERIFIER_URL}

verify:
	forge verify-contract --rpc-url ${RPC_URL} --verifier ${VERIFIER} --verifier-url ${VERIFIER_URL} ${CONTRACT_ADDRESS} ${CONTRACT_DETAIL}