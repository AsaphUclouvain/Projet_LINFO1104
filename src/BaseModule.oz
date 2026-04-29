functor
import
    System
export
    decode:Decode
    executeBlockchain:ExecuteBlockchain
define
    fun {TransitionHash T}
        (T.nonce+T.sender+T.receiver+T.value) mod {Pow 10 6}
    end
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
    %
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
                CurBalance := Balance.1
                CurNonce := Nonce.1
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
                CurBalance := Balance.1
                CurBalance := T.value
                true
            else
                {UpdateStateForReceiver T User Balance Nonce}
            end
        end
    end
    proc {AddBlock LastT curT }
    % This function update the Block and the 
    % State after validation
    proc {UpdateState Transactions User Balance Nonce BlockChain}
        %Add a new Transaction to the Block
        %check the max capacity (300)
        proc {UpdateBlock Block Transaction}
            MaxEffort = 300
        in

        end
        %compute the BlockHash and add a modified block to the Block chain
        proc {AddBlock Block PrevHash BlcokChain}

        end
        PrevTransaction = {NewCell nil}
        CurBlock
        PrevHash = {NewCell nil}
    in
        case Transactions of nil then
            {AddBlock @CurBlock @PrevHash BlockChain}
        [] H|T then
            if {ValidateTransaction H} then
                {UpdateStateForSender H @User @Balance @Nonce}
                if {UpdateStateForReceiver H @User @Balance @Nonce} == false then
                    User := T.receiver|@User
                    Balance := T.value|@Balance
                    Nonce := 0
                end
                if {Or @PrevTransaction==nil @PrevTransaction.number==H.number} then
                    {UpdateBlock CurBlock H}
                    PrevTransaction := H
                elseif {@PrevTransaction.number+1 == H.number} then
                    {AddBlock @CurBlock @PrevHash BlockChain}
                    PrevTransaction := nil
                    CurBlock := nil
                    PrevHash := nil 
                    {UpdateBlock CurBlock H}
                end
            end
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
        BlockChain = {NewCell nil}
    in
        %Extract genesis state and initiate the noce to 0
        %Process transactions in order
        %    For each transaction Check if valid with user Balance and Nonce
        %    If valid, add the transaction
        %    else skip it
        {ExtractGenesisState GenesisState User Balance Nonce}
        {UpdateState Transactions BlockChain User Balance Nonce}
    end
end