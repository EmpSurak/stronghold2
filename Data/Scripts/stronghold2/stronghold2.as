#include "timed_execution/timed_execution.as"
#include "timed_execution/after_init_job.as"
#include "timed_execution/delayed_job.as"
#include "timed_execution/repeating_delayed_job.as"
#include "timed_execution/on_input_pressed_job.as"
#include "timed_execution/on_input_down_job.as"
#include "timed_execution/after_char_init_job.as"
#include "timed_execution/char_damage_job.as"
#include "stronghold2/friend_controller.as"
#include "stronghold2/timed_execution/nav_destination_job.as"
#include "stronghold2/timed_execution/delayed_death_job.as"
#include "stronghold2/timed_execution/defeat_job.as"
#include "stronghold2/timed_execution/victory_job.as"
#include "stronghold2/common.as"
#include "stronghold2/constants.as"
#include "stronghold2/hudgui.as"
#include "stronghold2/end_screen.as"
#include "music_load.as"

TimedExecution timer;
FriendController friend_controller(timer);
HUDGUI@ hud_gui = HUDGUI();
EndScreen end_screen;

MusicLoad ml("Data/Music/stronghold2/stronghold2.xml");

float current_time = 0.0f;
int player_id = -1;
int casualties = 0;

void Init(string level_name){
    current_time = 0.0f;
    casualties = 0;
    SetTriumphant(false);

    timer.Add(DefeatJob(function(){
        casualties++;
        EndLevel("You failed!", false);
    }));

    timer.Add(VictoryJob(function(){
        level.SendMessage("victory");
        EndLevel("You stopped the simulation!", true, 5.0f);
    }));

    timer.Add(OnInputPressedJob(0, _key_reset, function(){
        if(EditorModeActive()){
            return true;
        }
        friend_controller.ShowYellDistance();
        friend_controller.Execute(function(_char){
            _char.Execute("combat_allowed = true;");
            _char.Execute("ResetMind();");
            friend_controller.Yell(_char.GetID(), "suspicious");
        });
        friend_controller.Yell(player_id, "engage");
        return true;
    }));

    timer.Add(OnInputPressedJob(0, _key_stand_down, function(){
        if(EditorModeActive()){
            return true;
        }
        friend_controller.ShowYellDistance();
        friend_controller.Execute(function(_char){
            _char.Execute("combat_allowed = false;");
        });
        friend_controller.Yell(player_id, "suspicious");
        return true;
    }));

    timer.Add(OnInputPressedJob(0, _key_come, function(){
        if(EditorModeActive()){
            return true;
        }
        friend_controller.ShowYellDistance();
        friend_controller.Execute(function(_char){
            MovementObject@ player_char = FindPlayer();
            friend_controller.NavigateToTarget(_char, player_char.position);
            friend_controller.Yell(_char.GetID(), "attack");
        });
        friend_controller.Yell(player_id, "attack");
        return true;
    }));

    timer.Add(OnInputPressedJob(0, _key_go_to, function(){
        if(EditorModeActive()){
            return true;
        }
        friend_controller.ShowYellDistance();
        friend_controller.Execute(function(_char){
            vec3 facing = camera.GetFacing();
            vec3 end = vec3(facing.x, max(-0.9, min(0.5f, facing.y)), facing.z) * 50.0f;
            vec3 hit = col.GetRayCollision(camera.GetPos(), camera.GetPos() + end);
            friend_controller.NavigateToTarget(_char, hit);
            friend_controller.Yell(_char.GetID(), "attack");
        });
        friend_controller.Yell(player_id, "attack");
        return true;
    }));

    timer.Add(OnInputPressedJob(0, _key_follow, function(){
        if(EditorModeActive()){
            return true;
        }
        friend_controller.ShowYellDistance();
        friend_controller.Execute(function(_char){
            _char.Execute("escort_id = " + player_id + ";");
            _char.Execute("SetGoal(_escort);");
            friend_controller.Yell(_char.GetID(), "engage");
        });
        friend_controller.Yell(player_id, "engage");
        return true;
    }));

    timer.Add(OnInputDownJob(0, _key_decrease_distance, function(){
        if(EditorModeActive()){
            return true;
        }
        friend_controller.SetYellDistance(friend_controller.GetYellDistance() - 0.1f);
        hud_gui.SetDistance(friend_controller.GetYellDistance());
        friend_controller.ShowYellDistance();
        return true;
    }));

    timer.Add(OnInputDownJob(0, _key_increase_distance, function(){
        if(EditorModeActive()){
            return true;
        }
        friend_controller.SetYellDistance(friend_controller.GetYellDistance() + 0.1f);
        hud_gui.SetDistance(friend_controller.GetYellDistance());
        friend_controller.ShowYellDistance();
        return true;
    }));

    timer.Add(OnInputPressedJob(0, _key_radius_1, function(){
        if(EditorModeActive()){
            return true;
        }
        friend_controller.SetYellDistance(2.0f);
        hud_gui.SetDistance(friend_controller.GetYellDistance());
        friend_controller.ShowYellDistance();
        return true;
    }));

    timer.Add(OnInputPressedJob(0, _key_radius_2, function(){
        if(EditorModeActive()){
            return true;
        }
        friend_controller.SetYellDistance(5.0f);
        hud_gui.SetDistance(friend_controller.GetYellDistance());
        friend_controller.ShowYellDistance();
        return true;
    }));

    timer.Add(OnInputPressedJob(0, _key_radius_3, function(){
        if(EditorModeActive()){
            return true;
        }
        friend_controller.SetYellDistance(10.0f);
        hud_gui.SetDistance(friend_controller.GetYellDistance());
        friend_controller.ShowYellDistance();
        return true;
    }));

    timer.Add(OnInputPressedJob(0, _key_radius_4, function(){
        if(EditorModeActive()){
            return true;
        }
        friend_controller.SetYellDistance(20.0f);
        hud_gui.SetDistance(friend_controller.GetYellDistance());
        friend_controller.ShowYellDistance();
        return true;
    }));

    timer.Add(OnInputPressedJob(0, _key_radius_5, function(){
        if(EditorModeActive()){
            return true;
        }
        friend_controller.SetYellDistance(40.0f);
        hud_gui.SetDistance(friend_controller.GetYellDistance());
        friend_controller.ShowYellDistance();
        return true;
    }));

    timer.Add(AfterInitJob(function(){
        player_id = FindPlayerID();

        timer.Add(AfterCharInitJob(player_id, function(_char){
            hud_gui.SetHealth(1.0f);
            hud_gui.SetDistance(friend_controller.GetYellDistance());
            _char.Execute("UpdateListener(camera.GetPos(), vec3(0, 0, 0), camera.GetFacing(), camera.GetUpVector());");

            timer.Add(CharDamageJob(player_id, function(_char, _p_blood, _p_permanent){
                float _blood = _char.GetFloatVar("blood_health");
                float _permanent = _char.GetFloatVar("permanent_health");
            
                if(_char.GetIntVar("knocked_out") != _awake){
                    hud_gui.SetHealth(0.0f);
                }else if(_blood < _permanent){
                    hud_gui.SetHealth(_blood);
                }else{
                    hud_gui.SetHealth(_permanent);
                }
                return true;
            }));

            RegisterCleanupJobs();
            RegisterMusicJobs();
        }));
        
        int num = GetNumCharacters();
        for(int i = 0; i < num; ++i){
            MovementObject@ char = ReadCharacter(i);
            Object@ char_obj = ReadObjectFromID(char.GetID());
            ScriptParams@ params = char_obj.GetScriptParams();
            if(params.HasParam(_unit_type_key)){
                string unit_type = params.GetString(_unit_type_key);
                if(unit_type == "Bomber"){
                    AddBomberJob(char.GetID());
                    char.Execute("no_fire_damage = true;");
                    char.Execute("SetOnFire(true);");
                }else if(unit_type == "Flag Bearer"){
                    AddFlagBearerJob(char.GetID());
                }
            }
        }
    }));
}

void Update(int is_paused){
    current_time += time_step;
    timer.Update();
    hud_gui.ShowPressedButtons();
    end_screen.Update();
}

bool HasFocus(){
    return false;
}

void DrawGUI(){
    hud_gui.Update();
    hud_gui.Render();
    end_screen.Render();
}

void ReceiveMessage(string msg){
    // The level messages are causing me problems, so I have decided to not use jobs for it.
    TokenIterator token_iter;
    token_iter.Init();

    if(!token_iter.FindNextToken(msg)){
        return;
    }

    string token = token_iter.GetToken(msg);

    if(token == "reset"){
        hud_gui.SetHide(false);
        end_screen.Reset();

        uint num_chars = GetNumCharacters();
        for(uint i = 0; i < num_chars; ++i){
            MovementObject@ char = ReadCharacter(i);
            Object@ char_obj = ReadObjectFromID(char.GetID());
            if(char_obj.IsExcludedFromSave()){
                QueueDeleteObjectID(char.GetID());
            }
        }

        uint num_items = GetNumItems();
        for(uint i = 0; i < num_items; ++i){
            ItemObject@ item = ReadItem(i);
            Object@ item_obj = ReadObjectFromID(item.GetID());
            if(item_obj.IsExcludedFromSave()){
                QueueDeleteObjectID(item.GetID());
            }
        }

        uint num_hotspots = GetNumHotspots();
        for(uint i = 0; i < num_hotspots; ++i){
            Hotspot@ hot = ReadHotspot(i);
            Object@ hot_obj = ReadObjectFromID(hot.GetID());
            if(hot_obj.IsExcludedFromSave()){
                QueueDeleteObjectID(hot.GetID());
            }
        }

        array<int> dynamic_lights = GetObjectIDsType(_dynamic_light_object);
        for(uint i = 0; i < dynamic_lights.length(); i++){
            Object@ light_obj = ReadObjectFromID(dynamic_lights[i]);
            ScriptParams@ _light_params = light_obj.GetScriptParams();
            if(light_obj.IsExcludedFromSave() && _light_params.HasParam(_magic_key)){
                QueueDeleteObjectID(dynamic_lights[i]);
            }
        }

        array<int> envs = GetObjectIDsType(_env_object);
        for(uint i = 0; i < envs.length(); i++){
            Object@ env_obj = ReadObjectFromID(envs[i]);
            if(env_obj.IsExcludedFromSave()){
                QueueDeleteObjectID(envs[i]);
            }
        }

        timer.DeleteAll();
    }else if(token == "post_reset"){
        timer.DeleteAll();
        Init("");
    }else if(token == "stronghold_death"){
        casualties++;
    }
}

void RegisterCleanupJobs(){
    timer.Add(RepeatingDelayedJob(1.0f, function(){
        MovementObject@ _player = ReadCharacterID(player_id);

        uint num_chars = GetNumCharacters();
        for(uint i = 0; i < num_chars; ++i){
            MovementObject@ char = ReadCharacter(i);
            Object@ char_obj = ReadObjectFromID(char.GetID());
            if(char_obj.IsExcludedFromSave()){
                bool far_away = distance(_player.position, char.position) > _char_deactivation_radius;
                int goal = char.GetIntVar("goal");
                bool has_goal = goal == _navigate || goal == _attack || goal == _escort;
                if(far_away && !has_goal){
                    char_obj.SetEnabled(false);
                }else{
                    char_obj.SetEnabled(true);
                }
            }
        }

        return true;
    }));
}

void RegisterMusicJobs(){
    timer.Add(RepeatingDelayedJob(0.2f, function(){
        if(IsTriumphant()){
            PlaySong("jubilee");
            return false;
        }

        MovementObject@ _char = ReadCharacterID(player_id);

        if(_char.HasFunction("int CombatSong()") && _char.QueryIntFunction("int CombatSong()") == 1){
            PlaySong("fate");
        }else{
            PlaySong("endurance");
        }

        return true;
    }));
}

void EndLevel(string message, bool win, float delay = 1.5f){
    hud_gui.SetHide(true);
    end_screen.ShowMessage(message, win, current_time, casualties);

    timer.Add(DelayedJob(delay, function(){
        end_screen.ShowControls();    
        RegisterKeys();
    }));
}

void RegisterKeys(){
    timer.Add(OnInputPressedJob(0, "space", function(){
        timer.Add(AfterInitJob(function(){
            level.SendMessage("reset");
        }));
        return false;
    }));

    timer.Add(OnInputPressedJob(0, "esc", function(){
        level.SendMessage("go_to_main_menu");
        return false;
    }));
}
