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
    proc {UpdateStateForSender T UserList BalList NonceList}
        case UserList#BalList#NonceList
        of (H|UTail)#(B|BTail)#(N|NTail) then
            if T.sender == H then
                B := @B - T.value
                N := T.nonce
            else
                {UpdateStateForSender T UTail BTail NTail}
            end
        [] nil#nil#nil then skip
        end
    end

    % Mise à jour du récepteur
    fun {UpdateStateForReceiver T UserList BalList NonceList}
        case UserList#BalList#NonceList
        of (H|UTail)#(B|BTail)#(N|NTail) then
            if T.receiver == H then
                B := @B + T.value
                true
            else
                {UpdateStateForReceiver T UTail BTail NTail}
            end
        [] nil#nil#nil then false
        end
    end
    fun {ReverseList Lst NewLst}
        case Lst of nil then NewLst
        [] H|T then {ReverseList T H|NewLst}
        end
    end

    % Fonctions de construction de blocs utilisées dans UpdateState
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

    % --- La fonction UpdateState récursive ---

    proc {UpdateState Transactions User Balance Nonce Blockchain}
        % On utilise des variables persistantes pour l'état du bloc en cours
        PrevTransaction = {NewCell nil}
        BlockTransactions = {NewCell nil}
        PreviousHash = {NewCell 0}

        proc {RecursiveUpdate Ts}
            case Ts of nil then
                if @BlockTransactions \= nil then
                    PreviousHash := {AddBlock (@PrevTransaction).block_number {ReverseList @BlockTransactions nil} @PreviousHash Blockchain}
                end
            [] H|T then
                if {ValidateTransaction H @User @Balance @Nonce} then
                    {UpdateStateForSender H @User @Balance @Nonce}

                    % Si un le receveur n'existe pas, on l'ajoute ici.
                    if {Not {UpdateStateForReceiver H @User @Balance @Nonce}} then
                        User := H.receiver|@User
                        Balance :={NewCell H.value}|@Balance
                        Nonce := {NewCell 0}|@Nonce
                    end
                    
                    % Logique de changement de bloc
                    if @PrevTransaction \= nil andthen H.block_number \= (@PrevTransaction).block_number then
                        PreviousHash := {AddBlock (@PrevTransaction).block_number {ReverseList @BlockTransactions nil} @PreviousHash Blockchain}
                        BlockTransactions := nil
                    end

                    {UpdateBlockTransactions BlockTransactions H}
                    PrevTransaction := H
                end
                {RecursiveUpdate T}
            end
        end
    in
        {RecursiveUpdate Transactions}
    end
    fun {BuildFinalState UserList BalList NonceList State}
        case UserList#BalList#NonceList
        of (H|UTail)#(B|BTail)#(N|NTail) then
            {BuildFinalState UTail BTail NTail state(H: user(balance:@B nonce:@N))|State}
        [] nil#nil#nil then State
        end
    end
    %% Return a string representation of the secret
    fun {Decode Blockchain}
        %% STUDENT START:
        %% TODO
        %% STUDENT END
        % Table de Sharelock : convertit un nombre (10-36) en caractère
        fun {GetLetter N}
            if N == 36 then & 
            elseif N >= 10 andthen N =< 35 then (N - 10) + &a
            else &? % Cas non défini (sécurité)
            end
        end

        % Extrait les paires d'une liste de chiffres
        fun {ProcessPairs Digits}
            case Digits
            of D1|D2|Rest then
                X = (D1 * 10 + D2)
                Nombre = (X mod 37)
                FinalN = if Nombre < 10 then 36 else Nombre end
            in
                {GetLetter FinalN} | {ProcessPairs Rest}
            [] _|nil then nil % Si impair, on ignore le dernier chiffre
            [] nil then nil
            end
        end

        % Traite chaque bloc de la blockchain[cite: 1]
        fun {LoopBlocks BL}
            case BL
            of B|Rest then
                % transforme le block en liste de chiffres
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
        FinalState = {ReverseList {BuildFinalState @User @Balance @Nonce nil} nil}
        FinalBlockchain = {ReverseList @Blockchain nil}
    end
end