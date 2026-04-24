**GUIDELINES SIMPLIFIED: OZ**



**BUT:**



Reconstituer et traiter la liste des transactions. Extraire la phrase secrete de l'etat final.





**TACHES:**



Implementation du système blockchain

Implementation de la fonction de décodage

Implementation des extensions.



**Implementation du systeme de blockchain**



Un blockchain est un ensemble de block lies. Chaque block representant des transactions.



\[transactions A]---\[transactions B]----\[transactions C]---....---\[transactions Z]



**Une transaction est un record:**



⟨transaction⟩ = {

&#x09;nonce : ⟨integer⟩,

&#x09;block\_number : ⟨integer⟩,

&#x09;hash : ⟨integer⟩,

&#x09;sender : ⟨integer⟩,

&#x09;receiver : ⟨integer⟩,

&#x09;value : ⟨integer⟩,

&#x09;effort : ⟨integer⟩,

&#x09;max\_effort : ⟨integer⟩

}



nonce: unique. numéro de la transaction. va de 1 a n+1 pour n transactions

block\_number: Le numero du block auquel appartient la transaction

hash: le hash de la transaction. != null et == resultat de la fonciton de hashage

sender: identifiant de l'envoyeur

receiver: identifiant de receveur

value: valeur envoyee par l'envoyeur au receveur. >= 0

effort: effort calculatoire necessaire a la transaction. == resultat de la fonction de calcul d'effort. >= 0

max\_effort: Effort maximal que l'envoyeur est pret a fournir. >= 0



**Un block est une liste de transactions:**



⟨block⟩ = {

&#x09;number : ⟨integer⟩,

&#x09;previousHash : ⟨integer⟩,

&#x09;transactions : ⟨list\_of\_transactions⟩,

&#x09;hash : ⟨integer⟩

}



number: numero du bloc dans la chaine. >=0 et == number\_precedent + 1

previousHash: hash du block precedent. >= 0 et == hash\_precedent

transactions: liste de transactions. != null et aucune transaction vide

hash: hash du block. != null et == resultat de la fonction hashage du block





Un blockchain est une liste de blocks:



⟨blockchain⟩ ::= nil | ⟨block⟩ ’|’ ⟨blockchain⟩



number: 0 ..... n



numéro de blocks croissant





**Fonctions a implementer:**



TransitionHash = (nonce + sender + reciever + value) mod 10^6



BlockHash = (number + previoushash + SUM de tous les hashTransaction) mod 10^6



effort = (SUM 2^i pour i allant de 0 a len(value) - 1) -- len(value) = nombre de digits



Validation de la transaction:

&#x09;nonce = nonce\_precedant + 1

&#x09;hash = resultat de la fonction de hashage

&#x09;le sender a suffisamment de fonds

&#x09;value >= 0

&#x09;max\_effort >= 0

&#x09;effort <= max\_effort



validation d'un block:

&#x09;number = number\_precedent + 1

&#x09;previousHash = hash\_block\_precedant

&#x09;hash = resultat de la fonction de hashage d'un block

&#x09;Toutes les transactions doivent etre valides

&#x09;l'effort du block (somme des efforts des transactions du block) <= 300

&#x09;



**Gestion des Etats:**



⟨state⟩ = {

&#x09;address1 : user(balance : int,nonce : int),

&#x09;address2 : user(balance : int,nonce : int),

&#x09;. . .

&#x09;}



addressX: address de l'utilisateur

balanceX: solde de l'utilisateur addressX

nonceX: dernier nonce utilisé par addressX



(On peut ajouter des champs dans le state record si necessaire)



Le record intiale (de l'etat du premier utilisateur) est le block genesis:



⟨genesis⟩ = { address1 : balance1,address2 : balance2,...}



Le blockchain est construit a partir de lui.



**Executer la blockchain:**



proc {ExecuteBlockchain GenesisState Transactions

FinalState FinalBlockchain}



GenesisState: record initial



Transactions: Liste triee des transactions par ordre de blocks croissant



Finalstate: variable non initialisée devant contenir l'etat final.



FinalBlockchain: variable non initialisée devant contenir le blockchain final



**Fonction de déchiffrage:**



Implementer une fonction de dechiffrage qui prend en entree la blockchain finale et retourne la phrase secrete.



PSEUDO\_CODE:



Pour chaque block de la blockchain:

&#x09;Recuperer le hash du block

&#x09;Pour chaque PAIRE de chiffres consécutifs C dans hash:

&#x09;	Nombre = X mod 37

&#x09;	Si Nombre est inferieur a 10

&#x09;		Nombre = 36

&#x09;	Convertir Nombre en lettre en utilisant le tableau de Sharelock

&#x09;Ajouter tous les caracteres obtenus a la phrase secrete

Retourner la phrase secrete





**Extensions:**



Implementer au moins deux des trois. ??(BaseModule.oz vs ExtentionsName.oz)



**Denylist:**



Ajouter un champ denylist au record blockchain. contiendra tous les utilisateurs ayant envoyé au moins trois transactions(valide ou non) au sein d'un meme block.



**L'effort n'est pas gratuit:**



L'effort calculée sera déduit du solde de l'utilisateur. Donc l'effort est une valeur monétaire tout comme **value** considérée dans la validation de la transaction.



**Féru des stats:**



fonction effectuant des operations statistiques sur la blockchain.


\_ fun {BiggestSenders Blockchain n}: retourne la liste des n utilisateurs ayant fait le plus de transactions (valides).



\_ fun {RecieveMost Blockchain n}: retourne une liste des n utilisateurs ayant recu la plus grande valeur totale de transaction.



\_ fun {MoneyPeak Blockchain}: retourne l'utilisateur qui a eu le solde le plus élevé a un moment donné de la blockchain, ainsi que le solde.



**RAPPORT:**



\_4 pages (5 pages 3 extensions implementées)

\_ Une page expliquant les choix dans l'implementation (RunBlockchain et

AppendToBlockchain en particulier)

\_ Representation de l'etat final de la blockchain et de la blockchain finale. (numero, hash, previousHash et le hash des transactions pour chaque block. rien de plus)

Afficher la phrase secrete obtenue.

\_Une page par extension. explication de l'implementation de l'etat final de la blockchain,

la liste des block et la phrase secrete.

\_Ajouter le NOM, PRENOM, et NOMA







