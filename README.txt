driftgame 0.1.4 by paramat
A game for Minetest Engine 5.2.0 and later
Derived from the 'minipeli' game by paramat

Authors of media
----------------
paramat (CC BY-SA 3.0):
  header.png
  icon.png

Description
-----------
This game uses a simple road generating mapgen to provide a suitable demonstration environment for my vehicle mod 'driftcar'.
The vehicle uses some physics modelling to create semi-realistic skidding and drifting behaviour.
Tyre grip is reduced on the grass nodes (nodes with the 'crumbly' group). 
Smoke particles are emitted from each tyre when skidding. 

Many existing games are not suitable as a demonstration environment for 'driftcar' as they use intensive ABMs or other intensive code that interferes with the control response of the vehicle.

Earlier versions of 'driftcar' mod
----------------------------------
'Driftcar' mod was previously released as a mod for 'Minetest Game' game.
The version in 'driftgame' game is an improved version and development of 'driftcar' will now continue in 'driftgame'.

Using 'driftcar' mod outside this game
--------------------------------------
This mod can be used in other Minetest games.
The vehicle's tyre grip is reduced on nodes with the 'crumbly' group, so it is a good idea for road nodes to belong to the 'cracky' group.
The vehicle responds best when used in games that do not run intensive code while the vehicle is being driven. If a non-lightweght Lua mapgen is used it is best to pre-generate an area before driving in that area.

Using this game
---------------
Due to client->server->client control delay it is recommended that this game is used in singleplayer or in local multiplayer.
Generation of new areas of world may slightly affect the control response of the vehicle, the best control response will occur in previously generated areas.
Third-person camera mode is recommended when driving for a better view.

How to start playing this game
------------------------------
Start a new world, the game will only allow 'Mapgen Flat' to be selected.
The optional features of Mapgen Flat: lakes and hills, should be left disabled.

When you enter the world, if the screen is black you are probably inside a tree, walk in various directions to exit the tree.

Type '/grantme all' to obtain all privileges.

Press 'K' to enable fly mode, and 'J' to enable fast mode.

Fly fast to find a road.

Place the car on the road, enter it. Press 'F7' to use third-person camera mode.

Car controls
------------
Left mouse button  = Place car in inventory when pointing at car.
Right mouse button = Place car in world. Enter or exit car when pointing at car.
Forward            = Speed up.
                     Slow down when moving backwards.
Backward           = Slow down.
                     Speed up when moving backwards.
Left               = Rotate anticlockwise.
Right              = Rotate clockwise.

How this game was created
-------------------------
This game is derived from my 'minipeli' game.

Minipeli mods used unaltered:
gui
hand
light
player_api

Minipeli mods used and altered:
mapgen (Remove sounds folder. Remove sounds tables. Remove river water nodes as mapgen valleys is unused. Alias "mapgen_river_water_source" to "mapgen:water_source" to avoid warnings)
media (remove sounds folder)
