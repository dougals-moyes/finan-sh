# finan-sh

This is largely the same code I wrote back in 2003, mainly
to see if it was possible to write usable software in Bourne
shell scripts, and also because I was a put off by the fact
GnuCash data files were incompatible between new versions.  I had
intended later to rewrite this in other languages. I have
released this as it may prove useful to others, or for those that
are curious about how such a system can be made.

**finan.sh** is a double-entry accounting system and general journal. It takes
one command line option: the directory where the journal file(s) are located. 

> finan.sh Path/To/JournalFilesDir

If the specified path doesn't exist, it will offer to create one for you.

Once a journal has been loaded, you will be presented with a simple menu:

```
  *****   
    *    Version 0.2 (Bourne Shell)      
    *  **** *  * * ***   ***   ** * *     
    *  *  * *  * **   * *   * *  ** *     
*   *  *  * *  * *      *   * *   * *     
 ***   **** **** *      *   *  ** * *     
 Using test-data journal
    a Add entries      aac add accounts 
                       al list accounts
    l list entries 

    p post (required to show balances) 
    b account balance
    ball balances for all accounts

    e exit
```
**NOTE:** Date formats are YYYYmmDD.

Type in the letter that corresponds to the desired function, and press enter:
+ acc adds an account (You will need to add accounts before doing anything else)
+ al List accounts already defined
+ l list journal entries
+ a adds a journal entry
+ p post -- this will post all journal entries not yet posed, and will allow for account balances
to be calculated
+ b get the balance of a specific account number
+ ball list the account balances of all accounts. The current version does not add the balances of
child accounts to parent accounts yet. This generates the bare minimum data that is needed
to create financial reports.
+ e exits.

Every change is immediately committed to disk. 

Just like in traditional double-entry accounting, there are 
five numbered account types: 
1. 1000's assets (bank accounts, investments,e etc)
2. 2000's liabilities (loans, credit cards, unpaid bills)
3. 3000's capital (net worth, usually computed at the end of the financial cycle when
revenue and expense accounts are closed out))
4. 4000's revenue (income)
5. 5000's expenses

The script understands the concept of sub-accounts. **5210.5200** means account 5210 is the sub
account of 5200. For example:
```
5750 Taxes
5751.5750 State Income Tax
5752.5750 Federal Income Tax
5759.5750 Other Taxes
```
You could edit these accounts manually by going to $DIR/COA, however changing the account 
numbers after they have been used would be a very bad idea. 

The journal only understands account numbers, but it will give you 
the opportunity to pull up an account list in case you forget the 
account number.

Posted accounts in the journal will appear with the account numbers
in square brackets **[1002]**, those that have not been posted (and, 
therefore won't be counted as part of the account balances), will 
show up in angle brackets **<1002>**. 

**finan.sh** uses simple file locking, so, in theory, multiple
instances can work on the same data.  There was the intent to add 
a non-interactive mode (and the code comments reflect that), but that 
was a very low priority. 

