// SPDX-License-Identifier: GPL-3.0

pragma solidity >= 0.7.0 < 0.9.0;

/**
* @dev Consortium system for participating airlines
*/
contract Airlines {
    address chairperson; // participant agent with highest privilege

    /// @notice request data
    struct ReqStruct {
        uint reqID;
        uint fID;
        uint numSeats;
        uint passengerID;
        address toAirline;
    }

    /// @notice response data
    struct RespStruct {
        uint reqID;
        bool status;
        address fromAirline;
    }

    mapping(address => uint ) escrow; // deposited escrow by each member airline
    mapping(address => uint) membership; // 1 if member else 0
    mapping(address => ReqStruct) reqs; // logged reqs by each member airline
    mapping(address => RespStruct) resps; // response
    mapping(address => uint) settledReqID;

    /// @dev throws when an unauthorized actor is trying to call a function
    /// @param _msg description
    error Unauthorized(string _msg);

    /// @dev throws when provided address isn't a member airline
    error NotAMember();

    /**
     * @dev emit when a request is sent `_fromAirline` to `_toAirline`
     * @param _reqID the ID of the request
     * @param _flightID flight ID
     * @param _numOfSeats number of seats requested
     * @param _custID ID of customer to transfer
     * @param _fromAirline address of airline making request
     * @param _toAirline address of airline receiving the request
     */
    event NewASKRequest(
        uint indexed _reqID, uint _flightID, 
        uint _numOfSeats, uint _custID, 
        address indexed _fromAirline, address indexed _toAirline
    );

    /**
     * @dev emit when a request is responded to
     * @param _reqID ID of the request 
     * @param _success status of the response. `true` if the request was attended to otherwise `false` 
     * @param _fromAirline the address of the airline that initially sent the request
     */
    event NewASKResponse(
        uint indexed _reqID, bool _success, address indexed _fromAirline
    );

    /**
     * @dev emit when payment settlement occurs for customer exchange between airlines
     * @param _fromAirline Airline making the settlement
     * @param _toAirline airline receiving the settlement
     * @param _reqID ID of the request whose payment is settled
     */
    event PaymentSettled(
        address indexed _fromAirline, address indexed _toAirline, uint indexed _reqID
    );

    /// @dev emit when member airline replenishes escrow
    /// @param _airline address of airline
    /// @param _amount the amount replenished
    event EscrowReplenished(
        address indexed _airline,
        uint _amount
    );

    /// @dev only chairperson can call functions guarded by this modifier
    modifier onlyChairperson {
        if(msg.sender != chairperson) revert Unauthorized("Only chairperson can call this function");
        _;
    }

    /// @dev only members can call functions guarded by this modifier
    /// @param _addr address to validate membership. 
    /// Note: If `address(0)` is provided, `msg.sender` will be used instead
    modifier onlyMember(address _addr) {
        if(_addr != msg.sender) {
            if(membership[_addr] != 1) revert NotAMember();
        } else {
            if(membership[msg.sender] != 1) revert Unauthorized("Only members can call this function");
        }
        _;
    }

    /// @notice constructor
    constructor() payable {
        chairperson = msg.sender;
        membership[msg.sender] = 1; // register msg.sender as a member
        escrow[msg.sender] = msg.value; // save the received fund as an escrow
    }

    /// @notice member airlines can self-register using this function
    function register() public payable {
        membership[msg.sender] = 1;
        escrow[msg.sender] = msg.value;
    }


    /// @notice remove airline from consortium
    /// @param _memberAirline address of the airline to remove
    function unregister(address _memberAirline) public onlyChairperson {
        uint airlineEscrow = escrow[_memberAirline];
        
        delete membership[_memberAirline]; // reset membership to zero
        delete escrow[_memberAirline]; // reset value to zero

        payable(_memberAirline).transfer(airlineEscrow); // transfer airline escrow back to their address
    }

    /**
     * @notice register a request for transfer of customer
     * @param _reqID ID of the request
     * @param _flightID the flight ID
     * @param _numOfSeats number of seats needed
     * @param _custID customer iD
     * @param _toAirline address of airline `msg.sender` is sending request to
     */
    function ASKRequest(
        uint _reqID,
        uint _flightID,
        uint _numOfSeats,
        uint _custID,
        address _toAirline
    ) public onlyMember(msg.sender) onlyMember(_toAirline) {
        ReqStruct memory req = ReqStruct({
            reqID: _reqID,
            numSeats: _numOfSeats,
            passengerID : _custID,
            toAirline : _toAirline,
            fID: _flightID
        });

        reqs[msg.sender] = req;

        emit NewASKRequest(
            _reqID, _flightID, 
            _numOfSeats, _custID, 
            msg.sender, _toAirline); // emit event
    }

    /**
     * @notice respond to a request
     * @param _reqID the ID Of the request
     * @param _success response status
     * @param _fromAirline the address of the airline that initially sent the request
     */
    function ASKResponse(
        uint _reqID, bool _success, address _fromAirline
    ) public onlyMember(msg.sender) onlyMember(_fromAirline) {
        RespStruct memory resp = RespStruct({
            reqID : _reqID,
            status : _success,
            fromAirline : _fromAirline
        });

        resps[msg.sender] = resp;

        emit NewASKResponse(_reqID, _success, _fromAirline); // emit event
    }

    /// @notice settle payment for a passenger exchange
    /// @param _reqID ID of the passenger exchange request
    /// @param _toAirline address of the airline who responded to the request and accepted passenger
    /// @param _numOfSeats the number of seats transacted
    function settlePayment(
        uint _reqID, address payable _toAirline, uint _numOfSeats
        ) public onlyMember(msg.sender) onlyMember(_toAirline) payable {

            // assuming price per seat is 1 ETH in WEI
            uint cost = _numOfSeats * 1e18;

            /// ensure `msg.sender` has enough escrow
            require(escrow[msg.sender] >= cost);

            // Ensure underflow and overflow doesn't occur
            require(escrow[msg.sender] - cost > type(uint).min && escrow[_toAirline] + cost <= type(uint).max);

            escrow[msg.sender] -= cost;
            escrow[_toAirline] += cost;

            settledReqID[msg.sender] = _reqID;

            emit PaymentSettled(msg.sender, _toAirline, _reqID); // emit event
    }

    /// @notice add escrow to be able to transact with other member airlines
    function replenishEscrow() public payable onlyMember(msg.sender) {
        escrow[msg.sender] += msg.value;

        emit EscrowReplenished(msg.sender, msg.value); // emit event
    }

}