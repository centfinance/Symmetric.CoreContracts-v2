// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../../../solidity-utils/contracts/openzeppelin/IERC20Permit.sol";
import "../../../solidity-utils/contracts/openzeppelin/IERC20PermitDAI.sol";
import "../../../vault/contracts/interfaces/IVault.sol";

import "../interfaces/IBaseRelayerLibrary.sol";

/**
 * @title VaultPermit
 * @notice Allows users to approve the Balancer Vault to use their tokens using permit (where supported)
 * @dev All functions must be payable so that it can be called as part of a multicall involving ETH
 */
abstract contract VaultPermit is IBaseRelayerLibrary {
    function vaultPermit(
        IERC20Permit token,
        address owner,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable {
        token.permit(owner, address(getVault()), value, deadline, v, r, s);
    }

    function vaultPermitDAI(
        IERC20PermitDAI token,
        address holder,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable {
        token.permit(holder, address(getVault()), nonce, expiry, allowed, v, r, s);
    }
}
