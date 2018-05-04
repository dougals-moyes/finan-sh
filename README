This is largely the same code I wrote back in 2003, mainly
to see if it was possible to write usable software in bourne
shell scripts, and also because I was a put off by the fact
GnuCash data files were incompatible between new versions.  I had
intended later to rewrite this in other languages. I have
released this as it may prove useful to others, or for those that
are curious about how such a system can be made.

finan.sh is a double-entry accounting system and general journal.
For those familiar with bookkeeping/paper systems, some of the 
aspects of the software will be familiar. There are five numbered
account types: 1000's assets, 2000's liabilities, 3000's capital,
4000's revenue, and 5000's expenses. The journal only understands
account numbers, but it will give you the opportunity to pull up
an account list in case you forget the account number.

Account balances are not available until the entries are posted.
This is a separate process.

finan.sh uses simple file locking, so, in theory, multiple
instances can work on the same data.

Posted accounts in the journal will appear with the account numbers
in square brackets [1002], those that have not been posted (and, therefore
won't show up when you check account balances), will show up in angle
brackets <1002>. 


