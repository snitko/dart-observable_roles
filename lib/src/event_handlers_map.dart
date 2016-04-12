part of observable_roles;

class EventHandlersMap {

  Map _map;

  EventHandlersMap([source_map=null]) {
    if(source_map is Map)
      _map = source_map;
    else
      _map = {};
  }

  add({event: null, role: null, handler: null}) {
    if(_map[event] == null)
      _map[event] = {};
    _map[event][role] = handler;
  }

  add_for_role(String role, Map handlers) {
    handlers.forEach((k,v) => this.add(event: k, role: role, handler: v));
  }

  add_for_event(String event, Map handlers) {
    handlers.forEach((k,v) => this.add(event: event, role: k, handler: v));
  }

  operator [](i) => _map[i]; 

}
