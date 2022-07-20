%lang starknet
from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IERC721:
    func balanceOf(owner: felt) -> (balance: Uint256):
    end

    func ownerOf(tokenId: Uint256) -> (owner: felt):
    end

    func safeTransferFrom(
            from_: felt, 
            to: felt, 
            tokenId: Uint256, 
            data_len: felt,
            data: felt*
        ):
    end

    func transferFrom(from_: felt, to: felt, tokenId: Uint256):
    end

    func approve(approved: felt, tokenId: Uint256):
    end

    func setApprovalForAll(operator: felt, approved: felt):
    end

    func getApproved(tokenId: Uint256) -> (approved: felt):
    end

    func isApprovedForAll(owner: felt, operator: felt) -> (isApproved: felt):
    end

    func mint(to : felt, tokenId : Uint256):
    end
end

@contract_interface
namespace zkBarterContract:
    func open_trade_request(
        token_a_address : felt,
        token_b_address : felt,
        token_a_id : Uint256,
        token_b_id : Uint256
    ):
    end
end

@external
func test_proxy_contract{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals
    local token_a_address : felt
    # We deploy contract and put its address into a local variable. Second argument is calldata array
    %{ 
        ids.token_a_address = deploy_contract("./lib/cairo_contracts/src/openzeppelin/token/erc721/ERC721_Mintable_Burnable.cairo", [1, 1, 123]).contract_address
        stop_prank_callable = start_prank(123, ids.token_a_address)
        print(ids.token_a_address)
    %}
    tempvar tokenIdA : Uint256 = Uint256(low=0, high=0)
    IERC721.mint(contract_address=token_a_address,to=123, tokenId=tokenIdA)
    let (owner) = IERC721.ownerOf(contract_address=token_a_address, tokenId=tokenIdA)
    assert owner = 123
    %{ stop_prank_callable() %}
    return()
end
