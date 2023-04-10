// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../src/damn-vulnerable-defi/DamnValuableToken.sol";
import "../../src/damn-vulnerable-defi/unstoppable/UnstoppableVault.sol";
import "../../src/damn-vulnerable-defi/unstoppable/ReceiverUnstoppable.sol";

contract UnstoppableTest is Test {
    address public deployer;
    address public player;
    address public someUser;
    DamnValuableToken public token;
    UnstoppableVault public vault;
    ReceiverUnstoppable public receiverContract;

    uint256 constant TOKENS_IN_VAULT = 1000000 * 1e18;
    uint256 constant INITIAL_PLAYER_TOKEN_BALANCE = 10 * 1e18;

    function setUp() public {
        deployer = vm.addr(1);
        player = vm.addr(2);
        someUser = vm.addr(3);
        vm.deal(deployer, 1 ether);
        vm.deal(player, 1 ether);
        vm.deal(someUser, 1 ether);

        vm.startPrank(deployer);
        token = new DamnValuableToken();
        vault = new UnstoppableVault(token, deployer, deployer);
        assertEq(address(vault.asset()), address(token));
        
        token.approve(address(vault), TOKENS_IN_VAULT);
        vault.deposit(TOKENS_IN_VAULT, deployer);
        vm.stopPrank();

        assertEq(token.balanceOf(address(vault)), TOKENS_IN_VAULT);
        assertEq(vault.totalAssets(), TOKENS_IN_VAULT);
        assertEq(vault.totalSupply(), TOKENS_IN_VAULT);
        assertEq(vault.maxFlashLoan(address(token)), TOKENS_IN_VAULT);
        assertEq(vault.flashFee(address(token), TOKENS_IN_VAULT -1), 0);
        assertEq(vault.flashFee(address(token), TOKENS_IN_VAULT), 50000 * 1e18);

        vm.prank(deployer);
        token.transfer(address(player), INITIAL_PLAYER_TOKEN_BALANCE);
        assertEq(token.balanceOf(address(player)), INITIAL_PLAYER_TOKEN_BALANCE);

        // Show it's possible for someUser to take out a flash loan
        vm.startPrank(someUser);
        receiverContract = new ReceiverUnstoppable(address(vault));
        receiverContract.executeFlashLoan(100 * 1e18);
        vm.stopPrank();
    }

    function testStopFlashloan() public {
        // Challenge #1 - Unstoppable
        // There’s a tokenized vault with a million DVT tokens deposited. It’s offering flash loans for free, until the grace period ends.
        // To pass the challenge, make the vault stop offering flash loans.
        // You start with 10 DVT tokens in balance.

        // Solution

        // It is no longer possible to execute flash loans
        vm.expectRevert();
        vm.startPrank(someUser);
        receiverContract.executeFlashLoan(100 * 1e18);
    }
}
