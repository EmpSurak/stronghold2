#include "timed_execution/timed_execution.as"
#include "timed_execution/char_damage_job.as"
#include "stronghold2/timed_execution/delayed_death_job.as"
#include "stronghold2/timed_execution/flag_bearer_job.as"
#include "stronghold2/timed_execution/flag_bearer_effect_job.as"
#include "stronghold2/constants.as"

void AddBomberJob(int _char_id){
    timer.Add(CharDamageJob(_char_id, function(_char, _p_blood, _p_permanent){
        // Explosion effect inspired by Gyrth' rocket mod.
        float radius = 15.0f;
        float critical_radius = 5.0f;

        array<int> nearby_characters;
        GetCharactersInSphere(_char.position, radius, nearby_characters);

        for(uint i = 0; i < nearby_characters.length(); i++){
            MovementObject@ nearby_char = ReadCharacterID(nearby_characters[i]);

            if(nearby_char.GetIntVar("updated") < 1){
                continue;
            }

            vec3 explode_direction = normalize(nearby_char.position - _char.position);
            float center_distance = distance(_char.position, nearby_char.position);
            float distance_alpha = 1.0f - (center_distance / radius);

            if(nearby_char.GetBoolVar("invincible")){
                if(nearby_char.controlled){
                    nearby_char.Execute("camera_shake += 2.0f;");
                }
                continue;
            }

            if(nearby_char.controlled){
                nearby_char.Execute("camera_shake += 10.0f;");
            }

            if(center_distance < critical_radius){
                nearby_char.Execute("ko_shield = 0;");
                nearby_char.Execute("SetOnFire(true);");
            }

            nearby_char.Execute("GoLimp(); TakeDamage(" + 2.0f * distance_alpha + ");");
            nearby_char.rigged_object().ApplyForceToRagdoll(
                explode_direction * 40000 * distance_alpha,
                nearby_char.rigged_object().skeleton().GetCenterOfMass()
            );
        }

        for(uint i = 0; i < 50; i++){
            MakeParticle(
                "Data/Particles/stronghold2/explosion_sparks.xml",
                _char.position,
                vec3(
                    RangedRandomFloat(-10.0f, 10.0f),
                    RangedRandomFloat(-10.0f, 10.0f),
                    RangedRandomFloat(-10.0f, 10.0f)
                )
            );
        }

        for(uint i = 0; i < 3; i++){
            MakeParticle(
                "Data/Particles/stronghold2/explosion_smoke.xml",
                _char.position,
                vec3(-2.0f)
            );
        }

        int explosion_number = rand()%3+1;
        string explosion_sound = "Data/Sounds/explosives/explosion" + explosion_number + ".wav";
        PlaySound(explosion_sound, _char.position);

        return false;
    }));
}

void AddFlagBearerJob(int _char_id){
    timer.Add(FlagBearerJob(2.0f, _char_id, function(_job, _char){
        timer.Add(LightUpJob(0.05f, 10.0f, _char.GetID(), function(_char, _light, _return_value){
            _light.SetTranslation(_char.position + vec3(0.0f, 2.5f, 0.0f));
            _light.SetTint(vec3(10.0f, _return_value, _return_value));
            return _return_value - 1.0f;
        }));

        float radius = 20.0f;
        string char_team = GetTeam(_char.GetID());

        array<int> nearby_characters;
        GetCharactersInSphere(_char.position, radius, nearby_characters);

        for(uint i = 0; i < nearby_characters.length(); i++){
            MovementObject@ _nearby_char = ReadCharacterID(nearby_characters[i]);
            bool is_flag_bearer = nearby_characters[i] == _char.GetID();
            bool is_dead = _char.GetIntVar("knocked_out") != _awake || _nearby_char.GetIntVar("knocked_out") != _awake;
            bool is_same_team = char_team == GetTeam(nearby_characters[i]);
            bool has_running_job = _nearby_char.GetBoolVar("invincible"); // FIXME: should be more generic
            if(is_flag_bearer || is_dead || !is_same_team || has_running_job){
                continue;
            }

            timer.Add(FlagBearerEffectJob(5.0f, _char.GetID(), nearby_characters[i], function(_char){
                _char.Execute("invincible = true;");

                for(uint i = 0; i < 3; i++){
                    MakeParticle(
                        "Data/Particles/stronghold2/flag_smoke.xml",
                        _char.position,
                        vec3(-1.0f)
                    );
                }
            }, function(_char){
                _char.Execute("invincible = false;");
            }));
        }
    }));
}

int FindPlayerID(){
    int num = GetNumCharacters();
    for(int i = 0; i < num; ++i){
        MovementObject@ char = ReadCharacter(i);
        if(char.controlled){
            return char.GetID();
        }
    }
    return -1;
}

MovementObject@ FindPlayer(){
    int player_id = FindPlayerID();
    MovementObject@ player_char = ReadCharacterID(player_id);
    return player_char;
}

array<string> FindHotspotsByNamePrefix(string _prefix){
    array<string> target_hotspots;

    array<int> all_hotspots = GetObjectIDsType(_hotspot_object);
    for(uint i = 0; i < all_hotspots.length(); i++){
        Object@ current_hotspot = ReadObjectFromID(all_hotspots[i]);
        string current_name = current_hotspot.GetName();
        if(current_name.findFirst(_prefix) == 0){
            target_hotspots.insertLast(current_name);
        }
    }

    return target_hotspots;
}

int FindFirstObjectByName(string _name){
    if(_name == ""){
        return -1;
    }

    array<int> objects = GetObjectIDs();
    for(uint i = 0; i < objects.length(); i++){
        Object@ obj = ReadObjectFromID(objects[i]);
        if(obj.GetName() == _name){
            return obj.GetID();
        }
    }

    return -1;
}

void RegisterCharCleanUpJob(TimedExecution@ _timer, MovementObject@ _char){
    _timer.Add(DelayedDeathJob(0.0f, _char.GetID(), function(_char){
        level.SendMessage("stronghold_death " + _char.GetID());
    }));

    _timer.Add(DelayedDeathJob(5.0f, _char.GetID(), function(_char){
        int emitter_id = CreateObject("Data/Objects/Hotspots/emitter.xml", true);
        Object@ emitter_obj = ReadObjectFromID(emitter_id);
        emitter_obj.SetTranslation(_char.position);
        emitter_obj.SetScale(0.1f);
        ScriptParams@ emitter_params = emitter_obj.GetScriptParams();
        emitter_params.SetString("Type", "Smoke");

        Object@ char_obj = ReadObjectFromID(_char.GetID());
        ScriptParams@ char_params = char_obj.GetScriptParams();
        char_params.AddInt(_smoke_emitter_key, emitter_id);
    }));

    _timer.Add(DelayedDeathJob(10.0f, _char.GetID(), function(_char){
        _char.Execute("SetOnFire(false);");

        int char_id = _char.GetID();
        Object@ char_obj = ReadObjectFromID(char_id);
        ScriptParams@ char_params = char_obj.GetScriptParams();
        int emitter_id = char_params.GetInt(_smoke_emitter_key);
        QueueDeleteObjectID(char_id);
        QueueDeleteObjectID(emitter_id);

        int num_items = GetNumItems();
        for(int i = 0; i < num_items; ++i){
            ItemObject@ item = ReadItem(i);
            Object@ item_obj = ReadObjectFromID(item.GetID());
            if(item.last_held_char_id_ == char_id && item_obj.IsExcludedFromSave()){
                QueueDeleteObjectID(item.GetID());
            }
        }
    }));
}

string GetTeam(int char_id){
    Object @_obj = ReadObjectFromID(char_id);
    ScriptParams @_params = _obj.GetScriptParams();
    return _params.GetString("Teams");
}

bool IsTriumphant(){
    ScriptParams@ level_params = level.GetScriptParams();
    return level_params.HasParam("triumphant") && level_params.GetString("triumphant") == "1";
}

void SetTriumphant(bool _value){
    ScriptParams@ level_params = level.GetScriptParams();
    level_params.SetString("triumphant", _value ? "1" : "0");
}

// based on (but modified) arena_level.as

vec3 GetRandomFurColor(){
    vec3 fur_color_byte;
    int rnd = rand()%6;
    switch(rnd){
        case 0: fur_color_byte = vec3(255); break;
        case 1: fur_color_byte = vec3(34); break;
        case 2: fur_color_byte = vec3(137); break;
        case 3: fur_color_byte = vec3(105, 73, 54); break;
        case 4: fur_color_byte = vec3(53, 28, 10); break;
        case 5: fur_color_byte = vec3(172, 124, 62); break;
    }
    return FloatTintFromByte(fur_color_byte);
}

vec3 ColorFromTeam(int which_team){
    switch(which_team){
        case 0: return vec3(1, 0, 0);
        case 1: return vec3(0, 0, 1);
        case 2: return vec3(0, 0.5f, 0.5f);
        case 3: return vec3(1, 1, 0);
    }
    return vec3(1, 1, 1);
}

vec3 FloatTintFromByte(const vec3 &in tint){
    vec3 float_tint;
    float_tint.x = tint.x / 255.0f;
    float_tint.y = tint.y / 255.0f;
    float_tint.z = tint.z / 255.0f;
    return float_tint;
}

vec3 RandReasonableColor(){
    vec3 color;
    color.x = rand()%255;
    color.y = rand()%255;
    color.z = rand()%255;
    float avg = (color.x + color.y + color.z) / 3.0f;
    color = mix(color, vec3(avg), 0.7f);
    return color;
}

