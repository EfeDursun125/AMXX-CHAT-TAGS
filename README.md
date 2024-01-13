# Amx Mod X CHAT TAGS
This plugin lets you to give players custom chat tags and it has build-in swear/bad word filter plus it has whitelist for words

# HOW TO USE?
1. Open chat_tags.ini in configs folder
2. Split username and tag with & and follow other steps if you want more options
3. To add *CHAT MESSAGE* colors use these: [color=green], [color=team], [color=default]
4. To disable swear/bad word filter for the player use this: [filter=false]
5. At final our file should look like this: OWNER[color=green][filter=false]

# CVars
- chat_tag_ct_name "Counter-Terrorist" // teamonly message for CT team
- chat_tag_tr_name "Terrorist" // teamonly message for TR team
- chat_tag_spec_name "SPEC" // message for spec
- chat_tag_dead_name "DEAD" // message for dead
- chat_tag_use_custom_folder "0" // to save custom dir, multi server support (2 servers 1 save file, players will be happy)
- chat_tag_custom_folder_dest "C:\ExampleFolder\cstrike\addons\amxmodx\configs" // path for custom dir, multiple servers can acces this path
