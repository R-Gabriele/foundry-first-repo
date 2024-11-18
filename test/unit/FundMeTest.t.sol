// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol"; // usiamo sempre lo script per deployare il contratto nel nostro test setup

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user"); // user è un indirizzo fittizio che uso per fare test. makeAddr è una funzione di forge-std che crea un indirizzo fittizio

    uint256 constant SEND_VALUE = 0.1 ether; // 100000000000000000 wei
    uint256 constant STARTING_BALANCE = 10 ether; // 1000000000000000000 wei

    //uint256 constant GAS_PRICE = 1;

    function setUp() external {
        // NB la funzione setUp() è chiamata automaticamente prima di ogni test!!
        //fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe(); //in questo modo chiamo lo script per deployare il contratto
        fundMe = deployFundMe.run(); //run è nello script DeployFundMe.s.sol . run ritorna un contratto FundMe deployato.Facendo cosi posso modificare solo lo script DeployFundMe.s.sol
        vm.deal(USER, STARTING_BALANCE); // deal è una cheatcode di forge-std che permette di inviare ether a un indirizzo fittizio
    }

    function testMinimumDollarIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMessageSender() public view {
        console.log("questo e il mio indirizzo che ho chiamato il test");
        console.log(msg.sender);
        //assertEq(fundMe.i_owner(), msg.sender);   Questo da errore perche il meg.sender sono io che chiamo il test
        // mentre il fundMe.i_owner() è l'indirizzo di FundMeTest
        assertEq(fundMe.getOwner(), msg.sender); // Questo invece funziona perche address(this) è l'indirizzo di FundMeTest
    }

    function testpriceFeedVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughEth() public {
        vm.expectRevert(); //hey, the next line , should revert
        // asserr(This tx fail/revert)
        fundMe.fund{value: 0}(); // send 0 eth => should fail => revert => il test passa
    }

    function testFundUpdatesFunderDataStructure() public {
        vm.prank(USER); // The next tx will be send by USER.    vm.prank è un cheatcode di foundry che permette di cambiare il msg.sender. funziona solo in test
        fundMe.fund{value: SEND_VALUE}(); // send 10 eth

        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArreyOfFunders() public {
        vm.prank(USER); // The next tx will be send by USER
        fundMe.fund{value: SEND_VALUE}(); // send 10 eth

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert(); //hey, the next line , should revert .   ignora la linea vm.prank, controlla che fundMe.withdraw() fallisca
        vm.prank(USER);
        fundMe.withdraw(); // should fail perche USER non è il owner quindi il test passa
    }

    function testWithDrawASingleFunder() public funded {
        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act

        vm.prank(fundMe.getOwner()); // The next tx will be send by the owner
        fundMe.withdraw();

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingOwnerBalance + startingFundMeBalance,
            endingOwnerBalance
        );
    }

    function testWithDrawFromMultipleFunders() public funded {
        uint160 numberOfFunders = 10; // uint160 perche se vogliamo generare indirizzi a partire da numeri, questi devono essere uint160
        uint160 startingFunderIndex = 2; // 2 per evitare di usare indice 0 e 1
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // creiamo una serie di funders che inviano ether al contratto
            //vm.prank(USER);
            //vm.deal (USER, SEND_VALUE);
            //address(0)    to generate an address
            hoax(address(i), SEND_VALUE); // hoax è un cheatcode che permette di inviare ether a un indirizzo fittizio. esegue vm.prank e vm.deal insieme
            fundMe.fund{value: SEND_VALUE}();
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
        console.log("Owner Balance: ", fundMe.getOwner().balance);
    }

    function testWithDrawFromMultipleFundersCheaper() public funded {
        uint160 numberOfFunders = 10; // uint160 perche se vogliamo generare indirizzi a partire da numeri, questi devono essere uint160
        uint160 startingFunderIndex = 2; // 2 per evitare di usare indice 0 e 1
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // creiamo una serie di funders che inviano ether al contratto
            //vm.prank(USER);
            //vm.deal (USER, SEND_VALUE);
            //address(0)    to generate an address
            hoax(address(i), SEND_VALUE); // hoax è un cheatcode che permette di inviare ether a un indirizzo fittizio. esegue vm.prank e vm.deal insieme
            fundMe.fund{value: SEND_VALUE}();
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
        console.log("Owner Balance: ", fundMe.getOwner().balance);
    }
}
