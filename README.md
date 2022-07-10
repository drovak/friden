# friden
Verilog models of Friden calculators, simulated using Verilator

## Updates:
 - 8 July 2022: Added an EC-130 simulator with OpenGL support
 - 6 July 2022: EC-132 and EC-130 (4 counter) models are tested and operational
 - 30 June 2022: EC-130 (3 counter) model is tested and operational

## Dependencies:  
 - verilator  
 - ncurses-dev (for terminal-based simulator)  
 - freeglut3-dev (for OpenGL-based simulator)  

## Screenshots:  
![EC-130 interactive simulator with OpenGL](ec130_gl/ec130_gl.png)

![EC-130 interactive simulator](ec130/ec130_interactive.png)

![EC-130 trace in GTKwave](ec130/ec130_trace.png)

## Basic build instructions:
 - Ensure Verilator is installed
 - If you are building an OpenGL version, ensure FreeGLUT is installed
 - Otherwise, ensure ncurses is installed
 - Within the simulator you wish to build, type `make notrace` to make
   an interactive simulator without creating a trace file
 - If you wish to create a trace file, type `make trace`

## Other notes:
 - The simulator may start in an odd state, as reset logic is not
   appropriately implemented. Simply press `c` to intialize the
   calculator.
 - The EC-130 has predefined decimal point selector switch positions
   compared to the EC-132, which offers any decimal point position.
   This feature has been applied to the EC-130 simulators, but could
   easily be reconfigured for authenticity. 
 - The OpenGL versions do not have an indicator for overflow (yet).

## Keyboard mappings:
| Keyboard      | EC-130               | EC-132               |
| ------------- | -------------------- | -------------------- |
| q             | [quit]               | SQUARE ROOT          |
| x             | [n/a]                | [quit]               |
| 0-9           | 0-9                  | 0-9                  |
| .             | DECIMAL POINT        | DECIMAL POINT        |
| enter         | ENTER                | ENTER                |
| r             | REPEAT               | REPEAT               |
| t             | STORE                | STORE                |
| e             | RECALL               | RECALL               |
| +             | ADD                  | ADD                  |
| -             | SUBTRACT             | SUBTRACT             |
| *             | MULTIPLY             | MULTIPLY             |
| /             | DIVIDE               | DIVIDE               |
| c             | CLEAR ALL            | CLEAR ALL[^1]        |
| backspace     | CLEAR ENTRY          | CLEAR ENTRY          |
| d             | [n/a]                | CLEAR DISPLAY        |
| o             | OVERFLOW LOCK        | OVERFLOW LOCK        |
| s             | CHANGE SIGN          | CHANGE SIGN          |
| up arrow      | [decimal selector++] | [decimal selector++] |
| down arrow    | [decimal selector--] | [decimal selector--] |

[^1]: This isn't a key on the EC-132, but is useful to initialize
the calculator to a known state.
