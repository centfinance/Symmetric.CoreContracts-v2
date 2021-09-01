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

import "@balancer-labs/v2-solidity-utils/contracts/math/Math.sol";
import "@balancer-labs/v2-solidity-utils/contracts/math/FixedPoint.sol";

contract LinearMath {
    using FixedPoint for uint256;

    // solhint-disable private-vars-leading-underscore

    struct Params {
        uint256 fee;
        uint256 rate;
        uint256 lowerTarget;
        uint256 upperTarget;
    }

    function _calcBptOutPerMainIn(
        uint256 mainIn,
        uint256 mainBalance,
        uint256 wrappedBalance,
        uint256 bptSupply,
        Params memory params
    ) internal pure returns (uint256) {
        // Amount out, so we round down overall.

        if (bptSupply == 0) {
            return _toNominal(mainIn, params);
        }

        uint256 previousNominalMain = _toNominal(mainBalance, params);
        uint256 afterNominalMain = _toNominal(mainBalance.add(mainIn), params);
        uint256 deltaNominalMain = afterNominalMain.sub(previousNominalMain);
        uint256 invariant = _calcInvariantUp(previousNominalMain, wrappedBalance, params);
        uint256 newBptSupply = bptSupply.mulDown(FixedPoint.ONE.add(deltaNominalMain.divDown(invariant)));
        return newBptSupply.sub(bptSupply);
    }

    function _calcBptInPerMainOut(
        uint256 mainOut,
        uint256 mainBalance,
        uint256 wrappedBalance,
        uint256 bptSupply,
        Params memory params
    ) internal pure returns (uint256) {
        // Amount in, so we round up overall.

        uint256 previousNominalMain = _toNominal(mainBalance, params);
        uint256 afterNominalMain = _toNominal(mainBalance.sub(mainOut), params);
        uint256 deltaNominalMain = previousNominalMain.sub(afterNominalMain);
        uint256 invariant = _calcInvariantDown(previousNominalMain, wrappedBalance, params);
        uint256 newBptSupply = bptSupply.mulDown(deltaNominalMain.divUp(invariant).complement());
        return bptSupply.sub(newBptSupply);
    }

    function _calcWrappedOutPerMainIn(
        uint256 mainIn,
        uint256 mainBalance,
        uint256 wrappedBalance,
        Params memory params
    ) internal pure returns (uint256) {
        // Amount out, so we round down overall.

        uint256 previousNominalMain = _toNominal(mainBalance, params);
        uint256 afterNominalMain = _toNominal(mainBalance.add(mainIn), params);
        uint256 deltaNominalMain = afterNominalMain.sub(previousNominalMain);
        uint256 newWrappedBalance = wrappedBalance.sub(deltaNominalMain.mulDown(params.rate));
        return wrappedBalance.sub(newWrappedBalance);
    }

    function _calcWrappedInPerMainOut(
        uint256 mainOut,
        uint256 mainBalance,
        uint256 wrappedBalance,
        Params memory params
    ) internal pure returns (uint256) {
        // Amount in, so we round up overall.

        uint256 previousNominalMain = _toNominal(mainBalance, params);
        uint256 afterNominalMain = _toNominal(mainBalance.sub(mainOut), params);
        uint256 deltaNominalMain = previousNominalMain.sub(afterNominalMain);
        uint256 newWrappedBalance = wrappedBalance.add(deltaNominalMain.mulUp(params.rate));
        return newWrappedBalance.sub(wrappedBalance);
    }

    function _calcMainInPerBptOut(
        uint256 bptOut,
        uint256 mainBalance,
        uint256 wrappedBalance,
        uint256 bptSupply,
        Params memory params
    ) internal pure returns (uint256) {
        // Amount in, so we round up overall.

        if (bptSupply == 0) {
            return _fromNominal(bptOut, params);
        }

        uint256 previousNominalMain = _toNominal(mainBalance, params);
        uint256 invariant = _calcInvariantUp(previousNominalMain, wrappedBalance, params);
        uint256 deltaNominalMain = invariant.mulUp(bptOut).divUp(bptSupply);
        uint256 afterNominalMain = previousNominalMain.add(deltaNominalMain);
        uint256 newMainBalance = _fromNominal(afterNominalMain, params);
        return newMainBalance.sub(mainBalance);
    }

    function _calcMainOutPerBptIn(
        uint256 bptIn,
        uint256 mainBalance,
        uint256 wrappedBalance,
        uint256 bptSupply,
        Params memory params
    ) internal pure returns (uint256) {
        // Amount out, so we round down overall.

        uint256 previousNominalMain = _toNominal(mainBalance, params);
        uint256 invariant = _calcInvariantDown(previousNominalMain, wrappedBalance, params);
        uint256 deltaNominalMain = invariant.mulDown(bptIn).divDown(bptSupply);
        uint256 afterNominalMain = previousNominalMain.sub(deltaNominalMain);
        uint256 newMainBalance = _fromNominal(afterNominalMain, params);
        return mainBalance.sub(newMainBalance);
    }

    function _calcMainOutPerWrappedIn(
        uint256 wrappedIn,
        uint256 mainBalance,
        Params memory params
    ) internal pure returns (uint256) {
        // Amount out, so we round down overall.

        uint256 previousNominalMain = _toNominal(mainBalance, params);
        uint256 deltaNominalMain = wrappedIn.mulDown(params.rate);
        uint256 afterNominalMain = previousNominalMain.sub(deltaNominalMain);
        uint256 newMainBalance = _fromNominal(afterNominalMain, params);
        return mainBalance.sub(newMainBalance);
    }

    function _calcMainInPerWrappedOut(
        uint256 wrappedOut,
        uint256 mainBalance,
        Params memory params
    ) internal pure returns (uint256) {
        // Amount in, so we round up overall.

        uint256 previousNominalMain = _toNominal(mainBalance, params);
        uint256 deltaNominalMain = wrappedOut.mulUp(params.rate);
        uint256 afterNominalMain = previousNominalMain.add(deltaNominalMain);
        uint256 newMainBalance = _fromNominal(afterNominalMain, params);
        return newMainBalance.sub(mainBalance);
    }

    function _calcInvariantUp(
        uint256 mainBalance,
        uint256 wrappedBalance,
        Params memory params
    ) internal pure returns (uint256) {
        return mainBalance.add(wrappedBalance.mulUp(params.rate));
    }

    function _calcInvariantDown(
        uint256 mainBalance,
        uint256 wrappedBalance,
        Params memory params
    ) internal pure returns (uint256) {
        return mainBalance.add(wrappedBalance.mulDown(params.rate));
    }

    function _toNominal(uint256 amount, Params memory params) internal pure returns (uint256) {
        if (amount < (FixedPoint.ONE - params.fee).mulUp(params.lowerTarget)) {
            return amount.divUp(FixedPoint.ONE - params.fee);
        } else if (amount < (params.upperTarget - params.fee).mulUp(params.lowerTarget)) {
            return amount.add(params.fee.mulUp(params.lowerTarget));
        } else {
            return
                amount.add((params.lowerTarget + params.upperTarget).mulUp(params.fee)).divUp(
                    FixedPoint.ONE + params.fee
                );
        }
    }

    function _fromNominal(uint256 nominal, Params memory params) internal pure returns (uint256) {
        if (nominal < params.lowerTarget) {
            return nominal.mulUp(FixedPoint.ONE - params.fee);
        } else if (nominal < params.upperTarget) {
            return nominal.sub(params.fee.mulUp(params.lowerTarget));
        } else {
            return
                nominal.mulUp(FixedPoint.ONE + params.fee).sub(
                    params.fee.mulUp(params.lowerTarget + params.upperTarget)
                );
        }
    }
}
