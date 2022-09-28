pragma solidity >= 0.7.0 < 0.9.0;

/**
* @dev Consortium system for participating airlines
*/
contract Airlines {
    address chairperson; // participant agent with highest privilege

    /// @notice request data
    struct reqStruct {
        uint reqID;
        uint fiD;
        uint numSeats;
        uint passengerID;
        address toAirline;
    }

    /// @notice response data
    struct respStruct {
        uint reqID;
        bool status;
        address fromAirline;
    }

}