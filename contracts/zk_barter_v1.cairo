%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import library_call

from interfaces.IERC721 import IERC721
from libraries.Ownable import Ownable
from libraries.Proxy import Proxy

#
# Structs
#

struct TradeRequest:
    member token_a_owner : felt
    member token_a_address : felt
    member token_b_address : felt
    member token_a_id : felt
    member token_b_id : felt
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
    token_a_id : felt,
    token_b_id : felt
) -> ():
    #Check for approval

    #Check for ownership

    #Read current trade request ID and create new one with id+1 

    #Set trade request id with status of OPEN in trade_request_statuses mapping

    #Emit TradeRequestOpened event with relevant info

    return()
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