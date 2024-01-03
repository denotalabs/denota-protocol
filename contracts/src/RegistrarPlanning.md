# NotaRegistrar Planning
Things to address and when to address them
## High-level Thoughts
* How permissionless should the protocol be? 
    * Whitelist modules by bytecode?? (constructors could include `owner`, `currency`, etc for customizability)
        * Permission levels: Address-> bytecode -> anyone
        * Reduces bytesData parameter length by hardcoding modules that can be frequently redeployed (execution vs storage cost tradeoff where long bytes can be encoded by module)
* Are hooks (modules) intended to be monolithic entities or frequently re-deployed? One for each fee manager, currency, etc
    * Decision parameters: 
        * Developer Experience: easier to deploy and understand, faster to iterate on concepts (many different hooks deployed)
        * Understandability: for end-users (can opensea users view the module and know what it means?)

## Version Planning
### V0.5 Stealth/beta deployment [reqs- prev. SDK/frontend compatibility, semi-permissioned]
* Keep module whitelisting using address ✅
* Emit MetadataUpdate() on every WTFC ✅
* Allow self-approval for Notas? [Look at ERC721] ✅
* Does opensea expect safeTransfer/From()? ✅ [KeptInCase]
* Refactor cashing token transfer logic into an internal function for readability ✅
* Separate _transferTokens into erc20/native transfer and moduleFee calc? ✅
* Change Nota struct `module` to interface types ✅ (`currency` not implemented though)
* Add back validWrite() check ✅
* Don't use moduleBytes in both transfer hook and _safeTransfer ✅
* Remove `createdAt` in Nota struct ✅
* Finish unit tests in registrar.t.sol ✅
* Remove native token? (simplifies escrow logic) ✅
* Is empty `moduleBytes` a security vulnerability? [Doesnt_affect_reversibleRelease] ✅
* Test if ERC721's work as is [Doesn't_work_with_moduleFee] ✅
* Check `if (_ownerOf(notaId) == address(0)) revert NotMinted();` OR `require(_exists(notaId), "");` in isMinted() saves more gas ✅
* Update DirectPay to be simpler (Pay module vs Invoice one) ✅
* Finish unit tests for (ReversibleRelease, DirectPay, Milestones) ✅
* Remove the bytes argument from processApproval() ✅
* Add ERC721 transfer checks IN ADDITION to whatever the module sets ✅
* Check that if module address has no code (DNE) transaction should fail

### V1 Audited Deployment [ABI_Breaking]
* Add functions for gettting WTFCA fees either as processXFees() to ModuleBase or as a separate interface
* Do events need timestamps?
* Consider removing nota struct in processX since only currency and escrowed matter
* Reconsider module bytecode approval and make constructor relaxed for customization. Can allow DAO to approve since metadata display is trusted
* Address bit flags (understand how incorrect bit flags affect things)     [000000 -> 111111] => [00 -> FF]
    * Could have standard WTFC subfunctions and module overrides. 
        * Ie `if (module.shouldCallTransferHook){ module allows non-standard transfers } else { require(_isApprovedOrOwner(notaId)) }`
        * `emit MetadataUpdate(notaId)` if module hook is used
* Add noDelegateCall in WTFCAB (if permissionless)
* Add burn(). Safety of transfers, reduces module transfer logic (gas cheaper)
* Ensure non-standard ERC20s function as expected (safeERC20 should handle this)
* Test/encourage re-entrancy by modules (use locker pattern from UniV4?)
* use struct in write (write(Nota calldata nota({escrowed, currency, module}), owner, instant, writeData)
* instantRecipient? Fund/Write assumes `owner` will get instant but cash doesn't assume who gets escrow
* Remove datatypes library? Remove WTFCFees struct?
* ModuleDecode(INotaModule module) external returns(string): ModuleDecode[module]=>“Writebytes(address,uint256,etc)”
* _abiDecode(bytes calldata moduleBytes){}
* Is `from` in processTransfer() needed? Can remove `from` from Written event as well
* Add moduleFee on approvals (changes ABI, does this affect the app?)
* Ensure consistency in function parameters for WTFCA and hooks
    [write(currency, escrowed, instant, owner, module, moduleBytes) -> 
     hook(msg.sender, owner, totalSupply, currency, escrowed, instant, moduleBytes)]
* Is it okay to pass storage variables like `totalSupply` to modules?
* rename processX() to beforeX()?
* remove ERC721's _msgSender()/Context dependency and hook functions? Could use Solmate
* is safeTransferFrom needed? Also add safeWrite()?
* add `approved` to fund and cash?
* how to improve the toJSON and importing?
* optimize gas by inspecting each OPCODE being used (get WTFCs cheaper)
* Should require statements be part of the module interface? canWrite(), canCash(), etc would allow people to query beforehand
* add module.getWTFCFee(params) -> uint256 within Registrar?
* isMinted() modifier allows interacting with burnt notas. isMinted(uint256 notaId)->if (_ownerOf(notaId) == address(0)) revert NotMinted(); increases gas (+70ish) for some reason

### V2 Audited Deployment
* Allow token deposit()/withdrawal() to avoid ERC20.transferFrom()'s
* Does tload and tstore factor here?
* Escrowing of ERC20/721/1155 tokens? (with deposit feature could still allow module fees)
* Allow modules to perform the escrow functionality? They can return the token that is escrowed (and fee) and registrar can check before and after module hook token.balanceOf()
* Combine Nota struct with `owner` and `approved` variables?
* before AND after hooks 
* ERC1155 instead of 721 for NOTAs
* Should we return selector vs fee for hooks  // Test if fallback not returning a uint256(BPSfee) fails
* Set fees on module construction by storing it on the registrar (+static, +immutable, +trusted, +predictable, -less custom) OR module fees using address bitmap? 
* Better packing of Nota packing (costly to store module address for every Nota) 
* Encode module properties within registrar (modules[module] => currency, prevents the need to save currency inside every Nota)
* Add referal in Nota struct? extra bits referral ID w/ mapping(uint16=>address) not use module fee (would only allow 65536 but could pay rent)
* Add mapping(address currency => uint256 escrow) to Nota struct
* 65 bits -> 16Hex (way too hard) but could be bit masks Fee=true/false: 1000[WTFC]= feeOnWrite only
    ModuleFees could be: 65 [uint72] (WTFC), 81 [88] (WTFCA), 97 [104] (WTFCAB)
    * 14bits has been used for very official (delegate.cash, Seaport)

### Front-End
* ChatGPT formatting of parameters "Send someone a direct payment with this URI"-> which is then formatted to the panel
* ChatGPT creating modules: "I want to send a person X token to release after they sign up to my website"

* Should the require statements be part of the interface? Would allow people to query canWrite(), canCash(), etc
* should make constructor call out to the NotaRegistrar to set fees? Would need to store that on both if there are subowners/dappOperators within the module so it can credit/withdraw those on the module's side
* Separate fee and non-fee ModuleBases (perhaps URI distinction ones as well?)

// NOTE cannot WTFC NFTs since _moduleRevenue treats moduleFee as fungible. NOTE: test if whitelisted how moduleWithdraw works
