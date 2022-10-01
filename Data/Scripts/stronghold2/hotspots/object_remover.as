const string _name_key = "Name";
const string _target_name_key = "Remover Name";
const string _name_default = "";

void Init(){
    ChangeObjects(false);
}

void SetParameters(){
    params.AddString(_name_key, _name_default);
}

void HandleEvent(string event, MovementObject @mo){
    if(!ReadObjectFromID(hotspot.GetID()).GetEnabled()){
        return;
    }

    if(!params.HasParam(_name_key) || params.GetString(_name_key) == ""){
        return;
    }

    if(event != "enter" && event != "exit"){
        return;
    }

    if(!mo.controlled){
        return;
    }

    ChangeObjects(event == "enter");
}

void Update(){}

void ChangeObjects(bool _status){
    array<int> objects = GetObjectIDs();
    for(uint i = 0; i < objects.length(); i++){
        Object@ obj = ReadObjectFromID(objects[i]);
        ScriptParams@ obj_params = obj.GetScriptParams();
        if(obj_params.HasParam(_target_name_key) && params.GetString(_name_key) == obj_params.GetString(_target_name_key)){
            obj.SetEnabled(_status);
        }
    }
}
