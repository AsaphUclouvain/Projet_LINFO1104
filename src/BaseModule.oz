functor
import
    System
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
    proc {ExtractGenesisState GS User Balance Nonce }
        proc {Helper K}
            case K of nil then skip
            [] H|T then
                User := H|@User
                Balance := {NewCell GS.H}|@Balance
                Nonce := {NewCell 0}|@Nonce
                {Helper T}
            end
        end
        Keys = {Arity GS}
    in
        {Helper Keys}
    end
    % User est une liste de constante
    % Balance et Nonce sont des listes d'addresses
    fun {ValidateTransaction T User Balance Nonce}
        case User
        of nil then false
        [] H|Tail then
            if T.sender == H then
                T.value >= 0 andthen
                T.value =< @(Balance.1) andthen
                T.hash == {TransitionHash T} andthen
                T.nonce == @(Nonce.1) + 1 andthen
                T.max_effort >= 0 andthen 
                {Effort T} =< T.max_effort
            else
                {ValidateTransaction T Tail Balance.2 Nonce.2}
            end
        end
    end
    %Should be called after the Transaction is validated with ValidateTransaction
    proc {UpdateStateForSender T User Balance Nonce}
        CurNonce
        CurBalance
    in
        case User of nil then skip
        [] H|Tail then
            if T.sender == H then
                CurBalance = Balance.1
                CurNonce = Nonce.1
                CurBalance := @CurBalance - T.value
                CurNonce := T.nonce
            else
                {UpdateStateForSender T Tail Balance.2 Nonce.2}
            end
        end
    end
    fun {UpdateStateForReceiver T User Balance Nonce}
        CurBalance
    in
        case User of nil then false
        [] H|Tail then
            if T.receiver == H then
                CurBalance = Balance.1
                CurBalance := @(Balance.1) + T.value
                true
            else
                {UpdateStateForReceiver T Tail Balance Nonce}
            end
        end
    end
    % Reverse a list
    fun {ReverseList Lst NewLst}
        case Lst of nil then NewLst
        [] H|T then
            {ReverseList T H|NewLst}
        end
    end
    % This function update the Block and the 
    % State after validation
    proc {UpdateState Transactions User Balance Nonce Blockchain}
        % Add a new Transaction to the Block
        % Check the max capacity (300)
        proc {UpdateBlockTransactions Ts T}
            MaxEffort = 300
        in
            if {TotalEffort Ts 0}+{Effort T} =< MaxEffort then
                Ts := tx(
                    nonce:T.nonce
                    block_number: T.number
                    hash:{TransitionHash T}
                    sender: T.sender
                    receiver: T.receiver
                    value: T.value
                    effort: {Effort T}
                    max_effort: T.max_effort
                )|@Ts
            end
        end
        %compute the BlockHash and add a modified block to the Block chain
        fun {AddBlock Number BT PrevHash BL}
            Hash = {BlockHash bl(number:Number previousHash:PrevHash transactions:BT)}
        in
            BL := bl(
                number:Number
                previousHash:PrevHash
                transactions:BT
                hash: Hash
            )|@BL
            Hash
        end
        PrevTransaction = {NewCell nil}
        BlockTransactions = {NewCell nil}
        PreviousHash = {NewCell 0}
    in
        case Transactions of nil then
            BlockTransactions := {ReverseList @BlockTransactions nil} % Reverse the list to the correct order
            if  @PrevTransaction == nil then
                PreviousHash := {AddBlock 0 @BlockTransactions @PreviousHash Blockchain}
            else
                PreviousHash := {AddBlock @PrevTransaction.block_number @BlockTransactions @PreviousHash Blockchain}
            end
        [] H|T then
            if {ValidateTransaction H @User @Balance @Nonce} then
                {UpdateStateForSender H @User @Balance @Nonce}
                if {UpdateStateForReceiver H @User @Balance @Nonce} == false then
                    User := T.receiver|@User
                    Balance := T.value|@Balance
                    Nonce := 0
                end
                if {Or @PrevTransaction==nil @PrevTransaction.block_number==H.block_number} then
                    {UpdateBlockTransactions BlockTransactions H}
                    PrevTransaction := H
                elseif {@PrevTransaction.block_number+1 == H.block_number} then
                    BlockTransactions := {ReverseList @BlockTransactions nil} % Reverse the list to the correct order
                    PreviousHash := {AddBlock @PrevTransaction.block_number @BlockTransactions @PreviousHash Blockchain}
                    PrevTransaction := nil
                    BlockTransactions := nil
                    PreviousHash := nil
                    {UpdateBlockTransactions BlockTransactions H}
                end
            end
            {UpdateState T User Balance Nonce Blockchain}
        else
            skip
        end
    end

    %% Return a string representation of the secret
    fun {Decode Blockchain}
        %% STUDENT START:
        %% TODO
        %% STUDENT END
        0
    end


    % This function is the starting point of the execution
    % The GenesisState and the Transactions are given as input and the function is expected to bound the FinalState and the FinalBlockchain to their respective final values.
    proc {ExecuteBlockchain GenesisState Transactions FinalState FinalBlockchain}
        %% STUDENT START:
        %% TODO
        %% STUDENT END
        User = {NewCell nil}
        Balance = {NewCell nil}
        Nonce = {NewCell nil}
        Blockchain = {NewCell nil}
    in
        %Extract genesis state and initiate the noce to 0
        %Process transactions in order
        %    For each transaction Check if valid with user Balance and Nonce
        %    If valid, add the transaction
        %    else skip it
        {ExtractGenesisState GenesisState User Balance Nonce}
        {UpdateState Transactions User Balance Nonce Blockchain}
        FinalBlockchain = {ReverseList @Blockchain nil}
    end
end