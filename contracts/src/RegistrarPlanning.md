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
* Consider inheriting from libraries for escrow functions
* Change "module" references to "hooks"
* rename processX() to beforeX()?
* Update the events so that Written doesn't have Transfer fields and change `Module` to indexed
* Remove events' timestamps parameter
* Remove Nota struct in processX since only currency and escrowed matter
* Remove the libraries from foundry (they show up in the verification)
* Add `burn()` and `processBurn()`
* Add hookFee on `approval()`
* Add totalSupply = 1 on construction to skip over 0th Nota (allows not-null checks)

* Use write struct if cheaper `write(Nota calldata nota({escrowed, currency, module}), owner, instant, writeData)`
* Remove DataTypes library if possible
* Address bit flags ie: [000000 -> 111111] => [00 -> FF]
    * Understand how incorrect bit flags affect safety
    * Could have standard WTFC functionality with hook overrides, ie: `if (hook.shouldCallTransferHook){ // hook allows non-standard transfers } else { require(_isApprovedOrOwner(notaId)) }`
    * `emit MetadataUpdate(notaId)` only if hook is used
    * Consider different options for hooks: CALL, SKIP, DISALLOW without calling the hook
* Make verification multi-part since (it's so long for block explorer users to find the right part)

* Add `approved` to fund and cash?
* Consider adding back batch functions
* Add noDelegateCall in WTFCAB (if permissionless) or lock pattern at least
* Ensure non-standard ERC20s function as expected (safeERC20 should handle this)
* Test/encourage re-entrancy by modules (use locker pattern from UniV4?)
* Ensure consistency in function parameters for WTFCA and hooks
    [write(currency, escrowed, instant, owner, module, moduleBytes) -> 
     hook(msg.sender, owner, totalSupply, currency, escrowed, instant, moduleBytes)]
* Is it okay to pass storage variables like `totalSupply` to modules?
* Remove ERC721's _msgSender()/Context dependency and hook functions? Could use Solmate
* Consider safeWrite()
* instantRecipient? Fund/Write assumes `owner` will get instant but cash doesn't assume who gets escrow
* Should require statements be part of the module interface? canWrite(), canCash(), etc would allow people to query beforehand
* ModuleDecode(INotaModule module) external returns(string): ModuleDecode[module]=>“Writebytes(address,uint256,etc)”
    * _abiDecode(bytes calldata moduleBytes){}
* Consider functions for getting WTFCA fees either as processXFees() to ModuleBase or as a separate interface
    * add module.getWTFCFee(params) -> uint256 within Registrar?

### V2 Audited Deployment
* Allow token `deposit()` / `withdrawal()` to avoid ERC20.transferFrom()'s
* Combine Nota struct with `owner` and `approved` variables
* add `afterX` hooks in addition to before
* ERC1155 (or 6909) instead of 721 for NOTAs [https://eips.ethereum.org/EIPS/eip-6909]. Also enables hooks to issue 1155 too
* Universal escrowing (ERC20/721/1155) tokens. (could take fee from deposit or require another token transfer)
* Multiple escrowing per Nota ie: mapping(address currency => uint256 escrow) in Nota struct
* Should we return selector vs fee for hooks  // Test if fallback not returning a uint256(BPSfee) fails
* Encode hook properties within registrar (hooks[hook] => currency, prevents the need to save currency inside every Nota)
* Use tload and tstore if applicable
* Allow hooks to take fees in other tokens
* Allow hooks to perform the escrow functionality? They can return the token that is escrowed (and fee) and registrar can check before and after hook hook token.balanceOf()
* Set fees on hook construction by storing it on the registrar (+static, +immutable, +trusted, +predictable, -less custom) OR hook fees using address bitmap? 
* Better packing of Nota packing (costly to store hook address for every Nota) 
* 65 bits -> 16Hex (way too hard) but could be bit masks Fee=true/false: 1000[WTFC]= feeOnWrite only
    HookFees could be: 65 [uint72] (WTFC), 81 [88] (WTFCA), 97 [104] (WTFCAB)
    * 14bits has been used for very official (delegate.cash, Seaport)

### Front-End
* ChatGPT formatting of parameters "Send someone a direct payment with this URI"-> which is then formatted to the panel
* ChatGPT creating modules: "I want to send a person X token to release after they sign up to my website"

* Should the require statements be part of the interface? Would allow people to query canWrite(), canCash(), etc
* should make constructor call out to the NotaRegistrar to set fees? Would need to store that on both if there are subowners/dappOperators within the module so it can credit/withdraw those on the module's side
* Separate fee and non-fee ModuleBases (perhaps URI distinction ones as well?)

### Hooks
* Look into using this for dates: [https://github.com/Vectorized/solady/blob/main/src/utils/DateTimeLib.sol]
