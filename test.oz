% declare
% fun {TransitionHash T}
%     (T.nonce+T.sender+T.receiver+T.value) mod {Pow 10 6}
% end
% fun {BlockHash B}
%     fun {SumHash Acc Transactions}
%         case Transactions of nil then Acc
%         [] H|T then {SumHash Acc+H.hash T}
%         end
%     end
%     Sum_hash = {SumHash 0 B.transactions}
% in
%     (B.number+B.previousHash+Sum_hash) mod {Pow 10 6}
% end
% fun {Effort T}
%     fun {CountDigits N}
%         {Length {Int.toString {Abs N}}}
%     end
%     N = {CountDigits T.value}
%     Res = {NewCell 0}
% in
%     for I in 0..(N-1) do
%         Res := @Res + {Pow 2 I}
%     end
%     @Res
% end
% T = tx(
%     block_number:13
%     nonce:13
%     hash:170
%     sender:13
%     receiver:13
%     value:131
%     max_effort:13
% )
% B = bl(
%     number: 12
%     hash: 132
%     previousHash: 17
%     transactions: T|T|nil
% )
% {Browse {Effort T}}
declare
Features = [field1 field2 field3]
R = {Record.make label Features}
{Browse R}
R.field1 = 100
R.field2 = 200