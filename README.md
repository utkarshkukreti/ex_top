# ExTop

ExTop is an interactive monitor for the Erlang VM written in Elixir.

## Demo

![Demo](https://i.imgur.com/G9grRie.gif)

## Prerequisites

* Erlang/OTP and Elixir
* A terminal emulator supporting ANSI escape sequences and having 120 or more
  columns and 14 or more rows.

## Installation

Clone this repository and execute `mix escript.build`. This will generate an
escript executable named `ex_top`, which can be executed by typing `./ex_top`

```
$ git clone https://github.com/utkarshkukreti/ex_top
$ cd ex_top
$ mix escript.build
$ ./ex_top
```

## Usage

### Keyboard Shortcuts

Key | Use
----|-----
j or Down Arrow | Select the next process.
k or Up Arrow | Select the previous process.
g | Select the first process.
G | Select the last process.
1-6 | Sort by the Nth column. Press again to toggle the sort order.
p | Pause/Unpause data collection.
q | Quit.

### Connecting to other nodes

```
./ex_top <other node name> --cookie <cookie>
```

## License
MIT
