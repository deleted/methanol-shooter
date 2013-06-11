methanol-shooter
================

This is control box firmware for the Serpent Mother's 12-valve methanol shooter.

This arduino sketch can drive a button box that controls 6 channels of liquid flame effects.  The special thing about liquid flame effects is that each fuel channel requires 2 valves:  One for the fuel and one for an inert purge gas that clears the line fuel line.

This code will hold a fuel valve open as long as you hold down the corresponding button.  When you let go, it closes the fuel valve and opens the purge valve, which it leaves open for a knob-adjustable delay time.
