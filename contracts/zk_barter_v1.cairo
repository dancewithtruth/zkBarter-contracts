%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import library_call, get_caller_address
from starkware.cairo.common.uint256 import Uint256

from interfaces.IERC721 import IERC721
from libraries.Ownable import Ownable
from libraries.Proxy import Proxy

#
# Events
#

@event
func trade_request_opened(
    id : felt,
    token_a_owner : felt,
    token_a_address : felt,
    token_b_address : felt,
    token_a_id_low : felt,
    token_a_id_high : felt,
    token_b_id_low : felt,
    token_b_id_high : felt,
):
end

@event
func trade_request_cancelled(id : felt):
end

@event
func trade_request_matched(id : felt):
end

#
# Structs
#

struct TradeRequest:
    member token_a_owner : felt
    member token_a_address : felt
    member token_b_address : felt
    member token_a_id : Uint256
    member token_b_id : Uint256
end

struct StatusEnum:
    member OPEN : felt
    member CANCELLED : felt
    member MATCHED : felt
end

#
# Storage variables
#

@storage_var
func trade_requests_num() -> (res : felt):
end

@storage_var
func trade_requests(trade_request_id : felt) -> (res : TradeRequest):
end

@storage_var
func trade_request_statuses(trade_request_id : felt) -> (res : felt):
end

#
# Intializer (to be called once from a proxy delegate call)
#

@external
func initializer{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
}(proxy_admin : felt):
    Proxy.initializer(proxy_admin=proxy_admin)
    return ()
end

#
# External functions
#

#To open a trade request, the requestor must own token A and have it be approved
@external
func open_trade_request{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    token_a_address : felt,
    token_b_address : felt,
    token_a_id : Uint256,
    token_b_id : Uint256
) -> (trade_request_id : felt):
    #Check for ownership
    let (caller) = get_caller_address()
    let (owner) = IERC721.ownerOf(contract_address=token_a_address, tokenId=token_a_id)
    with_attr error_message("Requestor is not the owner of ERC721 token for trade"):
        assert caller = owner
    end

    #Create new trade request with status OPEN
    let (current_id) = trade_requests_num.read()
    tempvar new_id = current_id + 1
    tempvar tr : TradeRequest = TradeRequest(
        token_a_owner=caller,
        token_a_address=token_a_address,
        token_b_address=token_b_address,
        token_a_id=token_a_id,
        token_b_id=token_b_id
    )
    trade_requests.write(trade_request_id=new_id, value=tr)
    trade_request_statuses.write(trade_request_id=new_id, value=StatusEnum.OPEN)
    trade_requests_num.write(value=new_id)

    trade_request_opened.emit(
        id=new_id,
        token_a_owner=caller,
        token_a_address=token_a_address,
        token_b_address=token_b_address,
        token_a_id_low=token_a_id.low,
        token_a_id_high=token_a_id.high,
        token_b_id_low=token_b_id.low,
        token_b_id_high=token_b_id.high
    )

    return (trade_request_id=new_id)
end

# Cancels an open trade request
@external
func cancel_trade_request{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(trade_request_id : felt) -> ():
    #Check if trade request was opened by caller
    let (caller) = get_caller_address()
    let (trade_request) = trade_requests.read(trade_request_id=trade_request_id)
    with_attr error_message("Cannot cancel a trade request that does not exist or does not belong to caller"):
        assert caller = trade_request.token_a_owner
    end
    let (trade_request_status) = trade_request_statuses.read(trade_request_id=trade_request_id)
    with_attr error_message("Trade request is not in OPEN status"):
        assert trade_request_status = StatusEnum.OPEN
    end
    trade_request_statuses.write(trade_request_id=trade_request_id, value=StatusEnum.CANCELLED)
    trade_request_cancelled.emit(id=trade_request_id)
    return()
end

# Matches against an open trade request
@external
func match_trade_request{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    trade_request_id
) -> ():
    #Check that trade request is open
    let (trade_request) = trade_requests.read(trade_request_id=trade_request_id)
    let (trade_request_status) = trade_request_statuses.read(trade_request_id=trade_request_id)
    with_attr error_message("Trade request is no longer valid"):
        assert trade_request_status = StatusEnum.OPEN
    end    

    #Check for ownership
    let (caller) = get_caller_address()
    let (owner) = IERC721.ownerOf(contract_address=trade_request.token_b_address, tokenId=trade_request.token_b_id)
    with_attr error_message("Matcher is not the owner of ERC721 token for trade"):
        assert caller = owner
    end

    #Swap NFTs
    IERC721.transferFrom(
        contract_address=trade_request.token_a_address,
        from_=trade_request.token_a_owner,
        to=caller,
        tokenId=trade_request.token_a_id
    )
    IERC721.transferFrom(
        contract_address=trade_request.token_b_address,
        from_=caller,
        to=trade_request.token_a_owner,
        tokenId=trade_request.token_b_id
    )

    #Update trade request status to MATCHED
    trade_request_statuses.write(trade_request_id=trade_request_id, value=StatusEnum.MATCHED)
    trade_request_matched.emit(
        id=trade_request_id
    )
    return ()
end

#
# Upgrades
#

@external
func upgrade{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(new_implementation: felt):
    Proxy.assert_only_admin()
    Proxy._set_implementation_hash(new_implementation)
    return ()
end

#
# Admin
#

@external
func set_admin{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(new_admin : felt):
    Proxy.assert_only_admin()
    Proxy._set_admin(new_admin=new_admin)
    return()
end