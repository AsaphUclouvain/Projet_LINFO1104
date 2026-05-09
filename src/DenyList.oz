functor
export
    decode:Decode
    executeBlockchain:ExecuteBlockchain
define
    % This function compute the hash of a transaction
    fun {TransitionHash T}
        (T.nonce+T.sender+T.receiver+T.value) mod {Pow 10 6}
    end

    % This function compute the hash of a Block
    fun {BlockHash B}
        fun {SumHash Acc Transactions}
            case Transactions of nil then Acc
            [] H|T then {SumHash Acc+H.hash T}
            end
        end
        Sum_hash = {SumHash 0 B.transactions}
    in
        (B.number+B.previousHash+Sum_hash) mod {Pow 10 6}
    end

    % This function compute the effort of a transaction
    fun {Effort T}
        fun {CountDigits N}
            {Length {Int.toString {Abs N}}}
        end
        N = {CountDigits T.value}
        Res = {NewCell 0}
    in
        for I in 0..(N-1) do
            Res := @Res + {Pow 2 I}
        end
        @Res
    end

    % This function compute the effort of a Block
    fun {TotalEffort Transactions E}
        case Transactions of nil then E
        [] Transaction|Tail then 
            {TotalEffort Tail E+{Effort Transaction}}
        end
    end

    % Extracts the first transaction data from the GenesisState (GS)
    proc {ExtractGenesisState GS User Balance Nonce CountTransac}
        proc {Helper K}
            case K of nil then skip
            [] H|T then
                User := H|@User
                Balance := {NewCell GS.H}|@Balance
                Nonce := {NewCell 0}|@Nonce
                CountTransac := ct(last_block:{NewCell ~1} count:{NewCell 0})|@CountTransac
                {Helper T}
            end
        end
        Keys = {Arity GS}
    in
        {Helper Keys}
    end

    % Validate a transaction
    fun {ValidTransaction T B N C}
        T.value >= 0 andthen
        T.value =< @B andthen
        T.hash == {TransitionHash T} andthen
        T.nonce == @N + 1 andthen
        T.max_effort >= 0 andthen
        @(C.count) =< 3 andthen
        {Effort T} =< T.max_effort
    end

    % update the sender data and returns true if the transaction is valid, else false
    fun {UpdateStateForSender T UserList BalList NonceList CountTList}
        case UserList#BalList#NonceList#CountTList
        of (H|UTail)#(B|BTail)#(N|NTail)#(C|CTail) then
            if T.sender == H then
                if @(C.count) < 3 andthen @(C.last_block) \= T.block_number then
                    (C.last_block) := T.block_number
                    (C.count) := 0
                end
                (C.count) := @(C.count) + 1

                if {ValidTransaction T B N C} then
                    B := @B - T.value
                    N := T.nonce
                    true
                else
                    false
                end
            else
                {UpdateStateForSender T UTail BTail NTail CTail}
            end
        [] nil#nil#nil#nil then false
        end
    end

    % update receiver data and returns true on success, false on failure
    fun {UpdateStateForReceiver T UserList BalList}
        case UserList#BalList
        of (H|UTail)#(B|BTail) then
            if T.receiver == H then
                B := @B + T.value
                true
            else
                {UpdateStateForReceiver T UTail BTail}
            end
        [] nil#nil then false
        end
    end

    % Returns a reversed version of a list
    fun {ReverseList Lst NewLst}
        case Lst of nil then NewLst
        [] H|T then {ReverseList T H|NewLst}
        end
    end

    % Builds the list of transactions of a block
    proc {UpdateBlockTransactions Ts T}
        MaxEffort = 300
    in
        if {TotalEffort @Ts 0} + {Effort T} =< MaxEffort then
            Ts := tx(
                nonce: T.nonce
                block_number: T.block_number
                hash: {TransitionHash T}
                sender: T.sender
                receiver: T.receiver
                value: T.value
                effort: {Effort T}
                max_effort: T.max_effort
            )|@Ts
        end
    end

    % Add a new block from the Block Transaction (BT) to the Blockchain (BL) and returns the computed hash
    fun {AddBlock Number BT PrevHash BL}
        Hash = {BlockHash bl(number:Number previousHash:PrevHash transactions:BT)}
    in
        BL := bl(
            number: Number
            previousHash: PrevHash
            transactions: BT
            hash: Hash
        )|@BL
        Hash
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % --- AppendToBlockFunction ---%

    proc {AppendToBlockchain Transactions User Balance Nonce CountTransac Blockchain}
        PrevTransaction = {NewCell nil}
        BlockTransactions = {NewCell nil}
        PreviousHash = {NewCell 0}

        proc {RecursiveAppend Ts}
            case Ts of nil then
                if @BlockTransactions \= nil then
                    PreviousHash := {AddBlock (@PrevTransaction).block_number {ReverseList @BlockTransactions nil} @PreviousHash Blockchain}
                end
            [] H|T then
                if {UpdateStateForSender H @User @Balance @Nonce @CountTransac} then
                    % If the receiver don't exists, we add him here
                    if {Not {UpdateStateForReceiver H @User @Balance}} then
                        User := H.receiver|@User
                        Balance :={NewCell H.value}|@Balance
                        Nonce := {NewCell 0}|@Nonce
                        CountTransac := ct(last_block:{NewCell ~1} count:{NewCell 0})|@CountTransac
                    end
                    
                    % current lock updating logic
                    if @PrevTransaction \= nil andthen H.block_number \= (@PrevTransaction).block_number then
                        PreviousHash := {AddBlock (@PrevTransaction).block_number {ReverseList @BlockTransactions nil} @PreviousHash Blockchain}
                        BlockTransactions := nil
                    end

                    {UpdateBlockTransactions BlockTransactions H}
                    PrevTransaction := H
                end
                {RecursiveAppend T}
            end
        end
    in
        {RecursiveAppend Transactions}
    end

    % Build the Final State of the Blockchain
    fun {BuildFinalState UserList BalList NonceList State}
        case UserList#BalList#NonceList
        of (H|UTail)#(B|BTail)#(N|NTail) then
            {BuildFinalState UTail BTail NTail state(H: user(balance:@B nonce:@N))|State}
        [] nil#nil#nil then State
        end
    end

    %% returns a string representation of the secret
    fun {Decode Blockchain}
        % Sharelock Table : convert a number (10-36) to character
        fun {GetLetter N}
            if N == 36 then & 
            elseif N >= 10 andthen N =< 35 then (N - 10) + &a
            else &? % undefined case (security)
            end
        end

        % Extract pairs from a list of digits
        fun {ProcessPairs Digits}
            case Digits
            of D1|D2|Rest then
                X = (D1 * 10 + D2)
                Nombre = (X mod 37)
                FinalN = if Nombre < 10 then 36 else Nombre end
            in
                {GetLetter FinalN} | {ProcessPairs Rest}
            [] _|nil then nil % we skip the last digit if odd
            [] nil then nil
            end
        end

        % Processes each block
        fun {LoopBlocks BL}
            case BL
            of B|Rest then
                % Turns the block hash into a list of digits
                HashStr = {Int.toString B.hash}
                Digits = {Map HashStr fun {$ C} C - &0 end}
            in
                {Append {ProcessPairs Digits} {LoopBlocks Rest}}
            [] nil then nil
            end
        end
    in
        {LoopBlocks Blockchain}
    end

    % This function is the starting point of the execution
    % The GenesisState and the Transactions are given as input and the function is expected to bound the FinalState and the FinalBlockchain to their respective final values.
    proc {ExecuteBlockchain GenesisState Transactions FinalState FinalBlockchain}
        User = {NewCell nil}
        Balance = {NewCell nil}
        Nonce = {NewCell nil}
        Blockchain = {NewCell nil}
        CountTransac = {NewCell nil}
    in
        {ExtractGenesisState GenesisState User Balance Nonce CountTransac}
        {AppendToBlockchain Transactions User Balance Nonce CountTransac Blockchain}
        FinalState = {ReverseList {BuildFinalState @User @Balance @Nonce nil} nil}
        FinalBlockchain = {ReverseList @Blockchain nil}
    end
end