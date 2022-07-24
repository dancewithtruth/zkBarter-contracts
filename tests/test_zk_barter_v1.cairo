%lang starknet
from starkware.cairo.common.uint256 import Uint256
from src.zk_barter_v1 import StatusEnum

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
namespace IBarterContract:
    func initializer(proxy_admin : felt):
    end

    func open_trade_request(
        token_a_address : felt,
        token_b_address : felt,
        token_a_id : Uint256,
        token_b_id : Uint256,
        isPrivate : felt,
        expiration : felt,
    ) -> (trade_request_id : Uint256):
    end

    func match_trade_request(trade_request_id : Uint256):
    end

    func get_trade_request_status(trade_request_id : Uint256) -> (res : felt):
    end
end

@external
func test_open_trade_request{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals
    local token_a_address : felt
    local token_b_address : felt
    local zk_barter_address : felt
    # We deploy contract and put its address into a local variable. Second argument is calldata array
    %{ 
        ids.token_a_address = deploy_contract("./lib/cairo_contracts/src/openzeppelin/token/erc721/ERC721_Mintable_Burnable.cairo", [1, 1, 111]).contract_address
        ids.token_b_address = deploy_contract("./lib/cairo_contracts/src/openzeppelin/token/erc721/ERC721_Mintable_Burnable.cairo", [1, 1, 222]).contract_address
        stop_prank_callable_a = start_prank(111, ids.token_a_address)
        stop_prank_callable_b = start_prank(222, ids.token_b_address)
        print(ids.token_a_address)
        print(ids.token_b_address)
    %}
    tempvar tokenIdA : Uint256 = Uint256(low=0, high=0)
    tempvar tokenIdB : Uint256 = Uint256(low=0, high=0)
    IERC721.mint(contract_address=token_a_address,to=111, tokenId=tokenIdA)
    IERC721.mint(contract_address=token_b_address,to=222, tokenId=tokenIdB)
    let (owner_a) = IERC721.ownerOf(contract_address=token_a_address, tokenId=tokenIdA)
    let (owner_b) = IERC721.ownerOf(contract_address=token_b_address, tokenId=tokenIdB)
    assert owner_a = 111
    assert owner_b = 222

    #Deploy and initialize zkBarter contract to start trading
    %{ 
        ids.zk_barter_address = deploy_contract("./src/zk_barter_v1.cairo", []).contract_address
        print(ids.zk_barter_address)
    %}
    IBarterContract.initializer(
        contract_address=zk_barter_address,
        proxy_admin=111
    )

    IERC721.setApprovalForAll(contract_address=token_a_address, operator=zk_barter_address, approved=1)
    IERC721.setApprovalForAll(contract_address=token_b_address, operator=zk_barter_address, approved=1)

    # User A opens trade request with User B
    %{ stop_zk_barter_callable = start_prank(111, ids.zk_barter_address)%}
    let (trade_request_id : Uint256) = IBarterContract.open_trade_request(
        contract_address=zk_barter_address,
        token_a_address=token_a_address,
        token_b_address=token_b_address,
        token_a_id=tokenIdA,
        token_b_id=tokenIdB,
        isPrivate=1,
        expiration=0
    )

    # Check to see if trade request status is OPEN (0)
    let (trade_request_status : felt) = IBarterContract.get_trade_request_status(
        contract_address=zk_barter_address,
        trade_request_id=trade_request_id
    )
    assert trade_request_status = StatusEnum.OPEN
    %{ stop_zk_barter_callable() %}

    # User B matches User A's trade request
    %{ stop_zk_barter_callable = start_prank(222, ids.zk_barter_address)%}
    IBarterContract.match_trade_request(contract_address=zk_barter_address, trade_request_id=trade_request_id)
    %{ stop_zk_barter_callable() %}

    let (owner_a) = IERC721.ownerOf(contract_address=token_a_address, tokenId=tokenIdA)
    let (owner_b) = IERC721.ownerOf(contract_address=token_b_address, tokenId=tokenIdB)
    assert owner_a = 222
    assert owner_b = 111

    %{ stop_prank_callable_a() %}
    %{ stop_prank_callable_b() %}
    return()
end
