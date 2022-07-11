%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import library_call

from interfaces.IERC721 import IERC721
from libraries.Ownable import Ownable
from libraries.Proxy import Proxy

struct TradeRequest:
    member id : felt
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

@storage_var
func trade_requests_num() -> (res : felt):
end

@storage_var
func trade_request_statuses(trade_request_id : felt) -> (status : felt):
end

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
func setAdmin{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(new_admin : felt):
    Proxy.assert_only_admin()
    Proxy._set_admin(new_admin=new_admin)
    return()
end