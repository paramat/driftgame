driftgame 0.1.3 by paramat
A game for Minetest Engine 5.2.0 and later
Built on the 'minipeli' game by paramat

Authors of media
----------------
paramat (CC BY-SA 3.0):
  header.png
  icon.png

Description
-----------
This game uses a simple road generating mapgen to provide a suitable demonstration environment for my vehicle mod 'driftcar'.
The vehicle uses some physics modelling to create semi-realistic skidding and drifting behaviour.
Many existing games are not suitable for 'driftcar' as they use intensive ABMs or other intensive code that interferes with the control response of the vehicle.

Earlier versions of 'driftcar' mod
----------------------------------
'Driftcar' mod was previously released as a mod for 'Minetest Game' game.
The version in 'driftgame' game is an improved version and development of 'driftcar' will now continue in 'driftgame'.
My GitHub repository for the 'Minetest Game' mod version will soon be deleted.

Using 'driftcar' mod outside this game
--------------------------------------
This mod can be used in other Minetest games.
Keep in mind that the vehicle's tyre grip is reduced on nodes with the 'crumbly' group, so it is a good idea for road nodes to belong to the 'cracky' group.
As mentioned earlier, the vehicle responds best when used in games that do not run intensive code while the vehicle is being driven. If a non-lightweght Lua mapgen is used it is best to pre-generate an area before driving in that area.

Using this game
---------------
Due to client->server->client control delay it is recommended that this game is used in singleplayer or in local multiplayer.
Generation of new areas of world may slightly affect the control response of the vehicle, the best control response will occur in previously generated areas.
Third-person camera mode is recommended when driving for a better view.
Arrow blocks are provided to mark out courses if desired.

How to start playing this game
------------------------------
Core mapgen decoration placement must be disabled (because the registered decorations are placed by Lua code in the 'track' mod instead). This can be done in the 'All Settings' menu (Settings tab -> All Settings -> Mapgen -> Mapgen flags) or by adding the line below to your minetet.conf file:
mg_flags = caves,dungeons,light,nodecorations,biomes

Start a new world, the game will only allow 'Mapgen Flat' to be selected.
The optional features of Mapgen Flat: lakes and hills, should be left disabled.

When you enter the world, if the screen is black you are probably inside a tree, walk in various directions to exit the tree.

Type '/grantme all' to obtain all privileges.

Press 'K' to enable fly mode, and 'J' to enable fast mode.

Fly fast to find some track.

Place the car on the track, enter it. Press 'F7' to use third-person camera mode.

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
