# ExTop

ExTop is an interactive monitor for the Erlang VM written in Elixir.

## Screenshots

![Screenshot](https://dl.dropboxusercontent.com/u/2164813/github/utkarshkukreti/ex_top/screenshot.png)

## Prerequisites

* Erlang/OTP and Elixir
* A terminal emulator supporting ANSI escape sequences and having atleast 120
  columns and 33 lines.

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
