// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Cooldowns {
    // Cooldown durations in blocks (assuming 0.5 seconds per block)
    uint32[14] public cooldowns = [
        uint32(120),      // 1 minute
        uint32(240),      // 2 minutes
        uint32(600),      // 5 minutes
        uint32(1200),     // 10 minutes
        uint32(3600),     // 30 minutes
        uint32(7200),     // 1 hour
        uint32(14400),    // 2 hours
        uint32(28800),    // 4 hours
        uint32(57600),    // 8 hours
        uint32(115200),   // 16 hours
        uint32(172800),   // 1 day
        uint32(345600),   // 2 days
        uint32(691200),   // 4 days
        uint32(1209600)   // 7 days
    ];
}
