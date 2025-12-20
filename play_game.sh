#!/bin/sh

rm -fv game.rbxl* game?.rbxl*
rojo build -o game.rbxl
open /Applications/RobloxStudio.app game.rbxl
