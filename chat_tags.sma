#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fakemeta>

const MAX_BAD_WORDS = 1024
const MAX_BAD_WORDS_LENGTH = 32
new badWords[MAX_BAD_WORDS][MAX_BAD_WORDS_LENGTH]
new badWordsCount

const MAX_ALLOWED_WORDS = 512
const MAX_ALLOWED_WORDS_LENGTH = 32
new allowedWords[MAX_ALLOWED_WORDS][MAX_ALLOWED_WORDS_LENGTH]
new allowedWordsCount

const MAX_RANDOM_NAMES = 128
const MAX_RANDOM_NAMES_LENGTH = 254
new randomNames[MAX_RANDOM_NAMES][MAX_RANDOM_NAMES_LENGTH]
new randomNamesCount

new clientTag[33][33]
new clientColor[33][5]
new bool:clientFilter[33]
new bool:clientBLOCK[33]

new ctTeam
new trTeam
new specName
new deadName
new tagCust
new tagDest

static Float:lastMessageTime
public plugin_init()
{
    register_plugin("Chat Tags With Filter", "1.2", "EfeDursun125")
    ctTeam = register_cvar("chat_tag_ct_name", "Counter-Terrorist")
    trTeam = register_cvar("chat_tag_tr_name", "Terrorist")
    specName = register_cvar("chat_tag_spec_name", "SPEC")
    deadName = register_cvar("chat_tag_dead_name", "DEAD")
    tagCust = register_cvar("chat_tag_use_custom_folder", "0")
    tagDest = register_cvar("chat_tag_custom_folder_dest", "C:\ExampleFolder\cstrike\addons\amxmodx\configs")
    register_message(get_user_msgid("SayText"), "customChatMessage")
    register_forward(FM_ClientUserInfoChanged, "clientBlockName")
    LoadWords()
    lastMessageTime = 0.0
}

public customChatMessage(msg_id, msg_dest, rcvr)
{
    new string[26]
    get_msg_arg_string(2, string, 25)

    if (!equal(string, "#Cstrike_Chat", 13))
        return PLUGIN_CONTINUE

    new Float:time = get_gametime()
    if (lastMessageTime > time)
        return PLUGIN_HANDLED

    new playerName[80]
    new playerTeamMessage[32]
    new chatMessage[256]
    new player = get_msg_arg_int(1)
    new CsTeams:playerTeam = cs_get_user_team(player)
    get_msg_arg_string(4, chatMessage, 255)
    trim(chatMessage)
    get_user_name(player, playerName, charsmax(playerName))
    new bool:isAlive = bool:is_user_alive(player)
    new bool:spec = false
    new pSize = charsmax(playerTeamMessage)
    new bool:teamSay = !equal(string, "#Cstrike_Chat_All", 17)
    if (!teamSay)
    {
        if (playerTeam != CS_TEAM_T && playerTeam != CS_TEAM_CT)
        {
            new teamName[28]
            get_pcvar_string(specName, teamName, charsmax(teamName))
            formatex(playerTeamMessage, pSize, "*%s* ", teamName)
            spec = true
        }
        else
            formatex(playerTeamMessage, pSize, "")
    }
    else
    {
        switch (playerTeam)
        {
            case CS_TEAM_T:
            {
                new teamName[28]
                get_pcvar_string(trTeam, teamName, charsmax(teamName))
                formatex(playerTeamMessage, pSize, "(%s) ", teamName)
            }
            case CS_TEAM_CT:
            {
                new teamName[28]
                get_pcvar_string(ctTeam, teamName, charsmax(teamName))
                formatex(playerTeamMessage, pSize, "(%s) ", teamName)
            }
            default:
            {
                new teamName[28]
                get_pcvar_string(specName, teamName, charsmax(teamName))
                formatex(playerTeamMessage, pSize, "(%s) ", teamName)
                spec = true
            }
        }
    }

    if (is_bad_word(player, chatMessage))
    {
        new text[255]
        if (!isAlive)
        {
            new teamName[32]
            get_pcvar_string(deadName, teamName, charsmax(teamName))
            formatex(text, charsmax(text), "^x01*%s* %s%s^x03%s ^x01:%s  %s", teamName, playerTeamMessage, clientTag[player], playerName, clientColor[player], chatMessage)
        }
        else
            formatex(text, charsmax(text), "^x01%s%s^x03%s ^x01:%s  %s", playerTeamMessage, clientTag[player], playerName, clientColor[player], chatMessage)

        message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, player)
        write_byte(player)
        write_string(text)
        message_end()
        server_print("Player %s used a bad word, and the message is hided from other players", playerName)
        server_print("Hidden message: %s", text)
    }
    else
    {
        new sayText = get_user_msgid("SayText")
        new maxPlayers = get_maxplayers() + 1
        for (new i = 1; i < maxPlayers; i++)
        {
            if (!is_user_connected(i))
                continue

            if (is_user_bot(i))
                continue

            if (teamSay && cs_get_user_team(i) != playerTeam)
                continue

            new text[255]
            if (!spec && !isAlive)
            {
                new teamName[32]
                get_pcvar_string(deadName, teamName, charsmax(teamName))
                formatex(text, charsmax(text), "^x01*%s* %s%s^x03%s ^x01:%s  %s", teamName, playerTeamMessage, clientTag[player], playerName, clientColor[player], chatMessage)
            }
            else
                formatex(text, charsmax(text), "^x01%s%s^x03%s ^x01:%s  %s", playerTeamMessage, clientTag[player], playerName, clientColor[player], chatMessage)

            message_begin(MSG_ONE_UNRELIABLE, sayText, _, i)
            write_byte(player)
            write_string(text)
            message_end()
        }
    }

    lastMessageTime = time + 0.111
    return PLUGIN_HANDLED
}

public client_putinserver(id)
{
    clientTag[id] = ""
    clientColor[id] = "^x01"
    clientFilter[id] = true
    clientBLOCK[id] = true
    if (is_user_bot(id))
    {
        clientFilter[id] = false
        clientBLOCK[id] = false
    }
    set_task(2.22, "client_load_tag", id)
}

public clientBlockName(id)
{
    if (!clientBLOCK[id])
        return FMRES_IGNORED
    
    static const name[] = "name"
    static szOldName[32], szNewName[32]
    pev(id, pev_netname, szOldName, charsmax(szOldName))
    if (szOldName[0])
    {
        get_user_info(id, name, szNewName, charsmax(szNewName))
        if (!equal(szOldName, szNewName))
        {
            set_user_info(id, name, szOldName)
            return FMRES_HANDLED
        }
    }

    return FMRES_IGNORED
} 

public client_load_tag(id)
{
    new playerName[255]
    get_user_name(id, playerName, charsmax(playerName))

    if (strlen(playerName) < 3)
        return

    trim(playerName)

    new path[255]
    if (get_pcvar_num(tagCust) != 1)
        get_configsdir(path, charsmax(path))
    else
    {
        new name[96]
        get_pcvar_string(tagDest, name, charsmax(name))
        formatex(path, charsmax(path), "%s", name)
    }

    new file[255]
    formatex(file, charsmax(file), "%s/chat_tags.ini", path)

    new line = 0
    new text[128]
    while (read_file(file, line, text, 128)) 
    {
        if (strlen(text) < 2)
            continue
        
        trim(text)

        if (strfind(text, playerName) != -1)
        {
            replace_all(text, charsmax(text), playerName, "")

            if (containi(text, "[color=green]") != -1)
                clientColor[id] = "^x04"
            else if (containi(text, "[color=team]") != -1)
                clientColor[id] = "^x03"
        
            if (containi(text, "[filter=off]") != -1)
                clientFilter[id] = false

            replace_all(text, charsmax(text), "[color=green]", "")
            replace_all(text, charsmax(text), "[color=team]", "")
            replace_all(text, charsmax(text), "[color=default]", "")
            replace_all(text, charsmax(text), "[filter=off]", "")
            replace_all(text, charsmax(text), "[filter=on]", "")

            trim(text)

            formatex(clientTag[id], 33, "^x04[%s]^x03 ", text)
        }

        line++
    }

    if (clientFilter[id])
    {
        clientBLOCK[id] = false

        new name[256]
        get_user_name(id, name, 255)
        if (is_bad_word(id, name))
            set_user_info(id, "name", randomNames[random_num(0, randomNamesCount - 1)])
        
        set_task(0.55, "client_block", id)
    }
}

public client_block(id)
{
    clientBLOCK[id] = true
}

LoadWords()
{
    new path[255]
    if (get_pcvar_num(tagCust) != 1)
        get_configsdir(path, charsmax(path))
    else
    {
        new name[96]
        get_pcvar_string(tagDest, name, charsmax(name))
        formatex(path, charsmax(path), "%s", name)
    }

    new file[255]
    formatex(file, charsmax(file), "%s/word_blacklist.ini", path)

    badWordsCount = 0
    new lineText[MAX_BAD_WORDS_LENGTH]
    while (badWordsCount < MAX_BAD_WORDS && read_file(file, badWordsCount, lineText, MAX_BAD_WORDS_LENGTH)) 
    {
        if (strlen(lineText) < 1)
            continue

        new size = charsmax(lineText)
        replace_all(lineText, size, "|<", "k")
        replace_all(lineText, size, "|>", "p")
        replace_all(lineText, size, "()", "o")
        replace_all(lineText, size, "[]", "o")
        replace_all(lineText, size, "{}", "o")
        replace_all(lineText, size, "@", "a")
        replace_all(lineText, size, "$", "s")
        replace_all(lineText, size, "0", "o")
        replace_all(lineText, size, "7", "t")
        replace_all(lineText, size, "3", "e")
        replace_all(lineText, size, "5", "s")
        replace_all(lineText, size, "<", "c")
        replace_all(lineText, size, "ç", "c")
        replace_all(lineText, size, "Ç", "c")
        replace_all(lineText, size, "ö", "o")
        replace_all(lineText, size, "Ö", "o")
        replace_all(lineText, size, "ş", "s")
        replace_all(lineText, size, "Ş", "s")
        replace_all(lineText, size, "ğ", "g")
        replace_all(lineText, size, "Ğ", "g")
        replace_all(lineText, size, "ı", "i")
        replace_all(lineText, size, "İ", "I")
        replace_all(lineText, size, "ü", "u")
        replace_all(lineText, size, "Ü", "u")
        replace_all(lineText, size, "ä", "a")

        trim(lineText)
        badWords[badWordsCount] = lineText
        badWordsCount++ 
    }

    formatex(file, charsmax(file), "%s/word_whitelist.ini", path)

    allowedWordsCount = 0
    new lineText2[MAX_ALLOWED_WORDS_LENGTH]
    while (allowedWordsCount < MAX_ALLOWED_WORDS && read_file(file, allowedWordsCount, lineText2, MAX_ALLOWED_WORDS_LENGTH)) 
    {
        if (strlen(lineText2) < 1)
            continue

        new size = charsmax(lineText2)
        replace_all(lineText2, size, "|<", "k")
        replace_all(lineText2, size, "|>", "p")
        replace_all(lineText2, size, "()", "o")
        replace_all(lineText2, size, "[]", "o")
        replace_all(lineText2, size, "{}", "o")
        replace_all(lineText2, size, "@", "a")
        replace_all(lineText2, size, "$", "s")
        replace_all(lineText2, size, "0", "o")
        replace_all(lineText2, size, "7", "t")
        replace_all(lineText2, size, "3", "e")
        replace_all(lineText2, size, "5", "s")
        replace_all(lineText2, size, "<", "c")
        replace_all(lineText2, size, "ç", "c")
        replace_all(lineText2, size, "Ç", "c")
        replace_all(lineText2, size, "ö", "o")
        replace_all(lineText2, size, "Ö", "o")
        replace_all(lineText2, size, "ş", "s")
        replace_all(lineText2, size, "Ş", "s")
        replace_all(lineText2, size, "ğ", "g")
        replace_all(lineText2, size, "Ğ", "g")
        replace_all(lineText2, size, "ı", "i")
        replace_all(lineText2, size, "İ", "I")
        replace_all(lineText2, size, "ü", "u")
        replace_all(lineText2, size, "Ü", "u")
        replace_all(lineText2, size, "ä", "a")

        trim(lineText2)
        allowedWords[allowedWordsCount] = lineText2
        allowedWordsCount++ 
    }

    formatex(file, charsmax(file), "%s/random_names.ini", path)

    randomNamesCount = 0
    new lineText3[MAX_RANDOM_NAMES_LENGTH]
    while (randomNamesCount < MAX_ALLOWED_WORDS && read_file(file, randomNamesCount, lineText3, MAX_RANDOM_NAMES_LENGTH)) 
    {
        if (strlen(lineText3) < 1)
            continue

        trim(lineText3)
        randomNames[randomNamesCount] = lineText3
        randomNamesCount++
    }
}

stock bool:is_bad_word(id, word[])
{
    if (!clientFilter[id])
        return false

    if (badWordsCount == 0)
        return false
    
    new cleaned_word[255]
    formatex(cleaned_word, charsmax(cleaned_word), word)

    if (allowedWordsCount != 0)
    {
        for (new i = 0; i < allowedWordsCount; i++)
            replace_all(cleaned_word, charsmax(cleaned_word), allowedWords[i], "")
    }

    new size = charsmax(cleaned_word)
    replace_all(cleaned_word, size, "|<", "k")
    replace_all(cleaned_word, size, "|>", "p")
    replace_all(cleaned_word, size, "()", "o")
    replace_all(cleaned_word, size, "[]", "o")
    replace_all(cleaned_word, size, "{}", "o")
    replace_all(cleaned_word, size, "@", "a")
    replace_all(cleaned_word, size, "$", "s")
    replace_all(cleaned_word, size, "0", "o")
    replace_all(cleaned_word, size, "7", "t")
    replace_all(cleaned_word, size, "3", "e")
    replace_all(cleaned_word, size, "5", "s")
    replace_all(cleaned_word, size, "<", "c")
    replace_all(cleaned_word, size, "ç", "c")
    replace_all(cleaned_word, size, "Ç", "c")
    replace_all(cleaned_word, size, "ö", "o")
    replace_all(cleaned_word, size, "Ö", "o")
    replace_all(cleaned_word, size, "ş", "s")
    replace_all(cleaned_word, size, "Ş", "s")
    replace_all(cleaned_word, size, "ğ", "g")
    replace_all(cleaned_word, size, "Ğ", "g")
    replace_all(cleaned_word, size, "ı", "i")
    replace_all(cleaned_word, size, "İ", "I")
    replace_all(cleaned_word, size, "ü", "u")
    replace_all(cleaned_word, size, "Ü", "u")
    replace_all(cleaned_word, size, "ä", "a")
    replace_all(cleaned_word, charsmax(cleaned_word), "_", "")
    replace_all(cleaned_word, charsmax(cleaned_word), "-", "")
    replace_all(cleaned_word, charsmax(cleaned_word), "|", "")
    replace_all(cleaned_word, charsmax(cleaned_word), ":", "")
    replace_all(cleaned_word, charsmax(cleaned_word), ";", "")
    replace_all(cleaned_word, charsmax(cleaned_word), ".", "")
    replace_all(cleaned_word, charsmax(cleaned_word), ",", "")
    replace_all(cleaned_word, charsmax(cleaned_word), "'", "")
    replace_all(cleaned_word, charsmax(cleaned_word), "%", "")
    replace_all(cleaned_word, charsmax(cleaned_word), "!", "")
    replace_all(cleaned_word, charsmax(cleaned_word), "?", "")
    replace_all(cleaned_word, charsmax(cleaned_word), " ", "")

    for (new i = 0; i < badWordsCount; i++)
    {
        if (containi(cleaned_word, badWords[i]) != -1)
            return true
    }

    return false
}
