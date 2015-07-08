# WonderlandAlice
A simple markov chain bot

## Installation
Requires `JSON`, `POE`, and `POE::Component::IRC`, all of which are of course
available from [CPAN](http://cpan.org).

## Configuration
Copy config.pm.example to config.pm and edit to match your setup.
WonderlandAlice does not support passwords, nickservs, SSL, or other advanced
authentication mechanisms.  PRs welcome.

## Creating your own markov chain
`markov.pl` transforms an input file into a JSON structure defining the
relationships between the words.  Use it like so:

    $ perl markov.pl text > chain.json

The bot loads the markov chain from chain.json when it starts up, so you will
have to restart the bot to load new data.  `markov.pl` also accepts a `--js`
flag that makes it output a JS snippet that loads the data into a `chain`
variable.  It's intended for use when embedding the chain into a JS program.
