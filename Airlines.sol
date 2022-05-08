pragma solidity >= 0.7.0 < 0.9.0;

/**
* @dev Consortium system for participating airlines
*/
contract Airlines {
    address chairperson; // participant agent with highest privilege
    struct details {
        uint escrow; // Deposits for payment settlement
        uint status;
        uint hashOfDetails;
    }

    mapping (address => details) public balanceDetails;
    mapping (address => uint) public membership;

    /** Specs */
    modifier onlyChairperson {
        require(msg.sender == chairperson);
        _;
    }

    modifier onlyMember {
        require(membership[msg.sender] == 1);
        _;
    }

    constructor() public payable {
         chairperson = msg.sender;
         membership[msg.sender] = 1;
         balanceDetails[msg.sender].escrow = msg.value
    }

    function register() public payable {
        address Airline = msg.sender;
        membership[Airline] = 1;
        balanceDetails[Airline].escrow = msg.value;
    }

    function (address payable Airline) public onlyChairperson {
        if (chairperson != msg.sender) { revert(); }

        membership[Airline] = 0;
        Airline.transfer(balanceDetails[Airline].escrow);
    }

    function request(address toAirline, uint _hashOfDetails) public onlyMember {
        if (membership[toAirline] != 1) { revert(); }

        balanceDetails[msg.sender].status = 0;
        balanceDetails[msg.sender].hashOfDetails = _hashOfDetails;
    }

    function response(address fromAirline, uint _hashOfDetails, uint done) pubic onlyMember {
        if (membership[fromAirline] != 1) { revert(); }

        balanceDetails[msg.sender].status = done;
        balanceDetails[fromAirline].hashOfDetails = hashOfDetails;
    }

    function settlePayment(address payable toAirline) public onlyMember payable {
        address fromAirline = msg.sender;

        uint amount = msg.value;
        balanceDetails[fromAirline].escrow -= amount;
        balanceDetails[toAirline].escrow += amount;

        toAirline.transfer(amount);
        
    }
}