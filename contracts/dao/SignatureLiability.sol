pragma solidity ^0.4.9;

import './LiabilityStandard.sol';
import 'common/Object.sol';

contract SignatureLiability is LiabilityStandard, Object {
    /**
     * @dev Liability constructor.
     * @param _promisee A person to whom a promise is made.
     * @param _promisor A person who makes a promise.
     */
    function SignatureLiability(address _promisee, address _promisor) payable {
        promisee    = _promisee;
        promisor    = _promisor;
    }

    /**
     * @dev I can receive payments.
     */
    function () payable {}

    /**
     * @dev Signature storage.
     *      It is boolean flag mapping from signed hash and signer address.
     */
    mapping(bytes32 => mapping(address => bool)) public hashSigned;

    /**
     * @dev Simple hash signatures checker.
     * @param _hash Signed hash.
     * @return Verification status.
     */
    function isSigned(bytes32 _hash) constant returns (bool)
    { return hashSigned[_hash][promisee] && hashSigned[_hash][promisor]; }

    /**
     * @dev Sign objective multihash.
     * @param _objective Production objective multihash.
     * @param _v Signature V param.
     * @param _r Signature R param.
     * @param _s Signature S param.
     * @notice Signature is eth.sign(address, sha3(objective))
     */
    function signObjective(
        bytes   _objective,
        uint8   _v,
        bytes32 _r,
        bytes32 _s
    )
      payable
      returns
    (
        bool success
    ) {
        // Objective notification
        Objective(_objective);

        // Signature processing
        var _hash   = sha3(_objective);
        var _sender = ecrecover(_hash, _v, _r, _s);
        hashSigned[_hash][_sender] = true;

        // Provision guard
        if (_sender == promisee)
            throw;

        // Objectivisation of proposals
        if (isSigned(_hash))
            objective = _objective;

        return true;
    }

    /**
     * @dev Sign result multihash.
     * @param _result Production result multihash.
     * @param _v Signature V param.
     * @param _r Signature R param.
     * @param _s Signature S param.
     * @notice Signature is eth.sign(address, sha3(sha3(objective), result))
     */
    function signResult(
        bytes   _result,
        uint8   _v,
        bytes32 _r,
        bytes32 _s
    ) returns (
        bool success
    ) {
        // Result notification
        Result(_result);

        // Signature processing
        var _hash   = sha3(sha3(objective), _result);
        var _sender = ecrecover(_hash, _v, _r, _s);
        hashSigned[_hash][_sender] = true;

        // Result handling
        if (isSigned(_hash)) {
            result = _result;

            if (!promisor.send(this.balance)) throw;
        }

        return true;
    }
}
